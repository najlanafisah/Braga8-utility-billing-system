@extends('layouts.app')

@section('content')
<div class="min-h-screen">
    <div class="mb-10 flex flex-col md:flex-row md:items-end justify-between gap-4 pb-8">
        <div>
            <h1 class="title-text">Usage Reports</h1>
            <p class="subtitle-text">Braga8 Utility Billing Management</p>
        </div>
        <div class="header-user">
            <div class="icon-wrapper" data-popup="notif-popup">
                <i class="fa-solid fa-bell"></i>
                <span class="notif-dot"></span>
            </div>
            <div class="profile-container" data-popup="detail-profile-popup">
                <div class="profile-icon">
                    <i class="fa-solid fa-user text-2xl text-[#a04d30]"></i>
                </div>
            </div>
        </div>
    </div>

    <div class="flex flex-col gap-6">
        <div class="toolbar flex items-end justify-between">
            <div class="flex flex-col w-64">
                <div class="search-wrapper !mb-0 w-full">
                    <input type="text" placeholder="Cari laporan (Contoh: April 2026)..." id="tableSearch">
                    <span><i class="fa-solid fa-magnifying-glass"></i></span>
                </div>
            </div>

            <div class="toolbar-action">
                <button type="button" class="light-brown-btn btn-small" data-popup="generate-report-modal">
                    <i class="fa-solid fa-plus mr-2"></i>
                    <span>Generate New Report</span>
                </button>
            </div>
        </div>

        @if($reports->count() > 0)
            @php $latest = $reports->first(); @endphp
            <div class="card-image-container mb-2">
                <div class="card card-with-image">
                    <div class="card-image"></div>
                    <div class="card-body">
                        <p class="card-label">Expected Revenue ({{ \Carbon\Carbon::parse($latest->month_year)->format('M Y') }})</p>
                        <p class="card-value">Rp {{ number_format($latest->total_revenue_expected, 0, ',', '.') }}</p>
                    </div>
                </div>
                <div class="card card-with-image">
                    <div class="card-image"></div>
                    <div class="card-body">
                        <p class="card-label">Total Electricity</p>
                        <p class="card-value">{{ number_format($latest->total_electric_usage) }} <span class="text-xs font-normal">kWh</span></p>
                    </div>
                </div>
                <div class="card card-with-image">
                    <div class="card-image"></div>
                    <div class="card-body">
                        <p class="card-label">Total Water</p>
                        <p class="card-value">{{ number_format($latest->total_water_usage) }} <span class="text-xs font-normal">m³</span></p>
                    </div>
                </div>
            </div>
        @endif

        <div class="table-wrapper">
            <div class="table-card mb-8">
                <div class="table-card-header">
                    <div class="table-card-title">
                        <span class="label">Total Reports:</span>
                        <span class="value">{{ $reports->count() }}</span>
                    </div>
                </div>
                <table class="table">
                    <thead>
                        <tr>
                            <th>Month / Year</th>
                            <th>Units Billed</th>
                            <th>Electricity (kWh)</th>
                            <th>Water (m³)</th>
                            <th>Total Revenue</th>
                            <th class="text-center">Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($reports as $report)
                        <tr>
                            <td class="font-bold text-zinc-800">
                                {{ \Carbon\Carbon::parse($report->month_year)->format('F Y') }}
                            </td>
                            <td><span class="blue-btn pointer-events-none">{{ $report->total_units_billed }} Units</span></td>
                            <td class="text-zinc-600 font-medium">{{ number_format($report->total_electric_usage) }}</td>
                            <td class="text-zinc-600 font-medium">{{ number_format($report->total_water_usage) }}</td>
                            <td class="font-bold text-[#602316]">
                                Rp {{ number_format($report->total_revenue_expected, 0, ',', '.') }}
                            </td>
                            <td class="actions">
                                <div class="flex justify-center">
                                    <a href="{{ route('reports.pdf', $report->id) }}" 
                                    class="light-green-btn-action px-4 py-2 flex items-center gap-2 relative z-[999]" 
                                    download> 
                                        <i class="fa-solid fa-file-pdf"></i>
                                        <span>Export PDF</span>
                                    </a>
                                </div>
                            </td>
                        </tr>
                        @empty
                        <tr>
                            <td colspan="6" class="p-10 text-center text-zinc-400 italic">
                                No reports found. Generate one to see the data.
                            </td>
                        </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<div class="popup" id="generate-report-modal">
    <div class="popup-overlay"></div>
    <div class="popup-card popup-md">
        <div class="popup-close-wrapper">
            <button class="popup-close" data-close="generate-report-modal">
                <i class="fa-solid fa-xmark"></i>
            </button>
        </div>
        <div class="popup-header">Generate Monthly Report</div>
        <div class="popup-body">
            <form action="{{ route('reports.generate') }}" method="POST">
                @csrf
                <div class="flex flex-col gap-6">
                    <div>
                        <div class="text-field">
                            <label class="text-field-label text-left text-zinc-700">Pilih Periode Laporan</label>
                            <input type="month" name="month" required 
                                class="text-field-input [color-scheme:light] cursor-pointer text-zinc-800 border-zinc-300">
                        </div>

                        <p class="text-xs text-zinc-400 italic">
                            Pilih periode bulan dan tahun untuk menghitung penggunaan listrik, air, dan estimasi pendapatan.
                        </p>
                    </div>

                    <button type="submit" class="dark-brown-button flex-[2] py-3"> 
                        Generate Sekarang
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>


@endsection