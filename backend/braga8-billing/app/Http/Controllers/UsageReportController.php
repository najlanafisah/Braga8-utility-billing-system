<?php

namespace App\Http\Controllers;

use App\Models\Invoice;
use App\Models\UsageReport;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;

class UsageReportController extends Controller
{

public function index()
{
    $reports = UsageReport::orderBy('month_year', 'desc')->get();
    return view('reports.index', compact('reports'));
}

public function generate(Request $request)
{
    $month = $request->input('month');

    $report = UsageReport::firstOrNew(['month_year' => $month]);
    $report->calculateMonthlyStats($month);

    return redirect()->route('reports.index')->with('success', 'Report generated for ' . $month);
}
public function exportPdf($id)
{
    $report = UsageReport::findOrFail($id);
    
    $dateParts = explode('-', $report->month_year);
    $year = $dateParts[0];
    $month = $dateParts[1];

    $invoices = Invoice::whereYear('billing_period_start', $year)
                ->whereMonth('billing_period_start', $month)
                ->with(['tenant', 'unit'])
                ->get();

    if (ob_get_contents()) ob_end_clean(); 

    $pdf = Pdf::loadView('pdf.usage-report', compact('report', 'invoices'));

    return $pdf->download("Usage-Report-{$report->month_year}.pdf");
}
}
