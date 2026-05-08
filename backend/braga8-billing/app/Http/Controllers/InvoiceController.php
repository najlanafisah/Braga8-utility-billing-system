<?php

namespace App\Http\Controllers;

use App\Models\Invoice;
use App\Models\Tenant;
use App\Models\Unit;
use App\Models\MeterReading;
use App\Models\Notification;
use App\Models\Tariff;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Barryvdh\DomPDF\Facade\Pdf;
use Carbon\Carbon;

class InvoiceController extends Controller
{
    public function index() {
        $invoices = Invoice::with(['tenant', 'unit'])->latest()->paginate(10);
        $tenants = Tenant::orderBy('tenant_name')->get();
        // Penting: Load meters dan tariff agar dropdown/filter lancar
        $units = Unit::with('meters.tariff')->get(); 

        return view('invoices.index', compact('invoices', 'tenants', 'units'));
    }

    public function store(Request $request) {
        $request->validate([
            'tenant_id' => 'required|exists:tenants,id',
            'unit_id'   => 'required|exists:units,id',
        ]);

        $unit = Unit::with(['meters.tariff'])->findOrFail($request->unit_id);
        $tenant = Tenant::findOrFail($request->tenant_id);

        $startDate = Carbon::now()->startOfMonth();
        $endDate   = Carbon::now()->endOfMonth();

        $readings = $this->calculateUsage($unit);
        
        if (isset($readings['error'])) {
            return back()->withErrors($readings['error'])->withInput();
        }

        // 3. Pastikan Meteran & Tariff Lengkap
        $elecMeter  = $unit->meters->where('meter_type', 'electricity')->first();
        $waterMeter = $unit->meters->where('meter_type', 'water')->first();

        if (!$elecMeter || !$waterMeter || !$elecMeter->tariff || !$waterMeter->tariff) {
            return back()->withErrors('Error: Meteran atau Data Tariff (Listrik/Air) belum di-set untuk unit ini.')->withInput();
        }

        $elecTariff  = $elecMeter->tariff;
        $waterTariff = $waterMeter->tariff;

        // 4. Perhitungan Biaya
        $waterUsage    = $readings['water_usage'];
        $electricUsage = $readings['electric_usage'];

        $waterCost    = $waterUsage * ($waterTariff->water_price ?? 0);
        $electricCost = $electricUsage * ($elecTariff->electric_price ?? 0);
        
        $otherFee = $request->filled('manual_other_fee') ? $request->manual_other_fee : ($elecTariff->other_fee ?? 0);

        $subtotal = $waterCost + $electricCost +
                    ($elecTariff->electric_load_cost ?? 0) +
                    ($elecTariff->transformer_maintenance ?? 0) +
                    ($elecTariff->admin_fee ?? 0) +
                    ($elecTariff->stamp_fee ?? 0) +
                    $otherFee;

        $taxRaw = ($subtotal * ($elecTariff->tax_percent ?? 0)) / 100;
        
        // 5. Pembulatan 1000
        $grandTotalRaw = $subtotal + $taxRaw;
        $totalRounded  = round($grandTotalRaw / 1000) * 1000;
        $roundingAdjustment = $totalRounded - $grandTotalRaw;

        // 6. Eksekusi Database
        return DB::transaction(function () use ($tenant, $unit, $startDate, $endDate, $totalRounded, $waterCost, $electricCost, $elecTariff, $otherFee, $taxRaw, $waterUsage, $electricUsage, $roundingAdjustment) {
            
            $invoice = Invoice::create([
                'tenant_id'            => $tenant->id,
                'unit_id'              => $unit->id,
                'invoice_number'       => 'INV-' . strtoupper(bin2hex(random_bytes(4))),
                'billing_period_start' => $startDate,
                'billing_period_end'   => $endDate,
                'total_amount'         => $totalRounded,
                'status'               => 'unpaid' // Pastikan ini ada di $fillable Model!
            ]);

            // Notification
            Notification::create([
                'user_id' => $tenant->user_id,
                'title'   => 'New Invoice',
                'message' => "Invoice {$invoice->invoice_number} bulan " . $startDate->translatedFormat('F Y') . " sudah terbit.",
                'type'    => 'invoice'
            ]);

            // Create Items
            $items = [
                ['description' => "Pemakaian Air ($waterUsage m3)", 'amount' => $waterCost],
                ['description' => "Pemakaian Listrik ($electricUsage kWh)", 'amount' => $electricCost],
                ['description' => 'Biaya Beban Listrik', 'amount' => $elecTariff->electric_load_cost ?? 0],
                ['description' => 'Pemeliharaan Trafo',  'amount' => $elecTariff->transformer_maintenance ?? 0],
                ['description' => 'Administrasi',        'amount' => $elecTariff->admin_fee ?? 0],
                ['description' => 'Materai',             'amount' => $elecTariff->stamp_fee ?? 0],
                ['description' => 'Lain-lain',           'amount' => $otherFee],
                ['description' => 'PPN ('.($elecTariff->tax_percent ?? 0).'%)', 'amount' => $taxRaw],
            ];

            if ($roundingAdjustment != 0) {
                $items[] = ['description' => 'Pembulatan', 'amount' => $roundingAdjustment];
            }

            foreach ($items as $item) {
                $invoice->items()->create($item);
            }

            return redirect()->route('invoices.index')->with('success', 'Invoice berhasil dibuat!');
        });
    }

    private function calculateUsage($unit) 
    {
        $elecMeter  = $unit->meters->where('meter_type', 'electricity')->first();
        $waterMeter = $unit->meters->where('meter_type', 'water')->first();

        if (!$elecMeter || !$waterMeter) {
            return ['error' => "Meteran Listrik/Air tidak ditemukan untuk unit ini."];
        }

        // Ambil 2 pembacaan terakhir yang sudah dicek
        $getReadings = function($meterId) {
            return MeterReading::where('meter_id', $meterId)
                                ->where('status', 'checked')
                                ->orderBy('reading_value', 'desc')
                                ->limit(2)
                                ->get();
        };

        $eReadings = $getReadings($elecMeter->id);
        $wReadings = $getReadings($waterMeter->id);

        if ($eReadings->count() < 2 || $wReadings->count() < 2) {
            return ['error' => "Data meteran (checked) masih kurang. Butuh minimal 2 data pembacaan terakhir."];
        }

        return [
            'electric_usage' => ($eReadings[0]->reading_value - $eReadings[1]->reading_value) * ($elecMeter->capacity ?? 1),
            'water_usage'    => ($wReadings[0]->reading_value - $wReadings[1]->reading_value) * ($waterMeter->capacity ?? 1),
        ];
    }

    public function show(Invoice $invoice) {
        $invoice->load(['tenant', 'unit', 'items']);
        return view('invoices.show', compact('invoice'));
    }

    public function pdf(Invoice $invoice) {
        $invoice->load(['tenant', 'unit', 'items']);
        $pdf = Pdf::loadView('invoices.pdf', compact('invoice'));
        return $pdf->download($invoice->invoice_number . '.pdf');
    }

    public function update(Request $request, Invoice $invoice) {
        $request->validate(['status' => 'required|in:unpaid,paid,canceled']);
        $invoice->update(['status' => $request->status]);
        return redirect()->back()->with('success', 'Status updated.');
    }

    public function destroy(Invoice $invoice) {
        $invoice->delete();
        return redirect()->route('invoices.index')->with('success', 'Invoice deleted.');
    }


    public function notifyTenant(Invoice $invoice)
{
    $tenant = $invoice->tenant;
    
    // Using 'contact_phone' and 'person_in_charge' from your Tenant model
    $phone = $tenant->contact_phone;
    $picName = $tenant->person_in_charge;

    if (!$phone) {
        return back()->with('error', 'No PIC phone number found for this tenant.');
    }

    // 1. Clean the phone number for WhatsApp
    $cleanPhone = preg_replace('/[^0-9]/', '', $phone);
    if (str_starts_with($cleanPhone, '0')) {
        $cleanPhone = '62' . substr($cleanPhone, 1);
    }

    // 2. Build the message with the items table
    $itemsList = "";
    foreach ($invoice->items as $item) {
        $itemsList .= "• " . $item->description . ": Rp " . number_format($item->amount) . "\n";
    }

    $message = "*TAGIHAN INVOICE: " . $invoice->invoice_number . "*\n" .
               "Gedung Braga 8\n" .
               "--------------------------\n" .
               "*PIC:* " . $picName . "\n" .
               "*Unit:* " . $invoice->unit->unit_number . "\n" .
               "--------------------------\n" .
               "*Detail Pemakaian:*\n" . 
               $itemsList .
               "--------------------------\n" .
               "*TOTAL TAGIHAN: Rp " . number_format($invoice->total_amount) . "*\n" .
               "--------------------------\n\n" .
               "Silahkan cek detail lengkap di aplikasi. Terima kasih.";

    // 3. Update the System (mark as notified)
    // Note: Make sure you ran the migration for 'notified_at'
    $invoice->update(['notified_at' => now()]);

    // 4. Redirect to WhatsApp
    $waUrl = "https://wa.me/" . $cleanPhone . "?text=" . urlencode($message);

    return redirect()->away($waUrl);
}

}