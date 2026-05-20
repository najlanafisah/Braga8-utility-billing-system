<?php

namespace App\Http\Controllers;

use App\Models\MeterReading;
use App\Models\Tenant;
use App\Models\UtilityMeter;
use App\Models\Unit;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class MeterReadingController extends Controller
{
    private function jsonResponse($message, $data = null, $status = 200)
    {
        return response()->json(['message' => $message, 'data' => $data], $status);
    }

    public function index(Request $request)
    {
        $search = $request->query('search');

        // Menggunakan paginate() menggantikan get() agar data tenant terbagi rapi
        $tenants = Tenant::with(['units.meters.readings.user'])
            ->when($search, function ($query) use ($search) {
                $query->where('tenant_name', 'LIKE', "%{$search}%")
                    ->orWhereHas('units', function ($q) use ($search) {
                        $q->where('unit_number', 'LIKE', "%{$search}%");
                    });
            })
            ->paginate(5)
            ->appends($request->all());

        $meters = UtilityMeter::with('unit')->get();

        return view('readings.index', compact('tenants', 'meters'));
    }

    public function updateStatus($id)
    {
        $reading         = MeterReading::findOrFail($id);
        $reading->status = $reading->status === 'checked' ? null : 'checked';
        $reading->save();
        return back()->with('status', 'reading-confirmed');
    }

    public function summary()
    {
        $tenants = Tenant::with(['units.meters.readings' => function ($query) {
            $query->latest();
        }])->get();
        return response()->json($tenants);
    }

    public function getMonthlyProgress()
    {
        $totalMeters       = UtilityMeter::count();
        $readingsThisMonth = MeterReading::whereMonth('recorded_at', now()->month)
            ->whereYear('recorded_at', now()->year)
            ->distinct('meter_id')
            ->count();

        return response()->json([
            'total'      => $totalMeters,
            'readings'   => $readingsThisMonth,
            'percentage' => $totalMeters > 0 ? round($readingsThisMonth / $totalMeters, 2) : 0,
        ]);
    }

    private function getAddress($lat, $lon)
    {
        if (!$lat || !$lon || ($lat == 0 && $lon == 0)) {
            return "Koordinat tidak valid (GPS tidak terkunci)";
        }

        try {
            $response = Http::withHeaders([
                'User-Agent' => 'Braga8-Ujikom-App-Student-Project', 
                'Accept' => 'application/json',
            ])
            ->timeout(10)
            ->get("https://nominatim.openstreetmap.org/reverse", [
                'format' => 'jsonv2', 
                'lat'    => $lat,
                'lon'    => $lon,
                'addressdetails' => 1,
            ]);

        if ($response->successful()) {
            $data = $response->json();
            return $data['display_name'] ?? "Alamat tidak ditemukan di peta";
        }

        Log::error("Nominatim Error: " . $response->status() . " - " . $response->body());
        return "Gagal melacak alamat (Server Map Error)";
        
        } catch (\Exception $e) {
            Log::error("Geo Error: " . $e->getMessage());
            return "Gagal melacak alamat (Koneksi Timeout)";
        }
    }
}