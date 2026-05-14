@extends('layouts.app') 

@section('content') 
<div class="min-h-screen"> 
    <div class="mb-10 flex flex-col md:flex-row md:items-end justify-between gap-4 pb-8"> 
        <div> 
            <h1 class="title-text">Laporan Penggunaan</h1> 
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
                    <i class="fa-solid fa-plus mr-2"></i> <span>Buat Laporan Baru</span> 
                </button> 
            </div> 
        </div> 

        @if($reports->count() > 0) 
            @php 
                $latest = $reports->first(); 
                \Carbon\Carbon::setLocale('id');
            @endphp 
            <div class="card-image-container mb-2"> 
                <div class="card card-with-image"> 
                    <div class="card-image"></div> 
                    <div class="card-body"> 
                        <p class="card-label">Estimasi Pendapatan ({{ \Carbon\Carbon::parse($latest->month_year)->translatedFormat('M Y') }})</p> 
                        <p class="card-value">Rp {{ number_format($latest->total_revenue_expected, 0, ',', '.') }}</p> 
                    </div> 
                </div> 
                <div class="card card-with-image"> 
                    <div class="card-image"></div> 
                    <div class="card-body"> 
                        <p class="card-label">Total Penggunaan Listrik</p> 
                        <p class="card-value">{{ number_format($latest->total_electric_usage) }} <span class="text-xs font-normal">kWh</span></p> 
                    </div> 
                </div> 
                <div class="card card-with-image"> 
                    <div class="card-image"></div> 
                    <div class="card-body"> 
                        <p class="card-label">Total Penggunaan Air</p> 
                        <p class="card-value">{{ number_format($latest->total_water_usage) }} <span class="text-xs font-normal">m³</span></p> 
                    </div> 
                </div> 
            </div> 
        @endif 

        <div class="table-wrapper"> 
            <div class="table-card mb-8"> 
                <div class="table-card-header"> 
                    <div class="table-card-title"> 
                        <span class="label">Total Laporan:</span> 
                        <span class="value">{{ $reports->count() }}</span> 
                    </div> 
                </div> 
                <table class="table"> 
                    <thead> 
                        <tr> 
                            <th>Bulan / Tahun</th> 
                            <th>Unit Ditagih</th> 
                            <th>Listrik (kWh)</th> 
                            <th>Air (m³)</th> 
                            <th>Total Pendapatan</th> 
                            <th class="text-center">Aksi</th> 
                        </tr> 
                    </thead> 
                    <tbody> 
                        @forelse($reports as $report) 
                            <tr> 
                                <td class="font-bold text-zinc-800"> 
                                    {{ \Carbon\Carbon::parse($report->month_year)->translatedFormat('F Y') }} 
                                </td> 
                                <td><span class="blue-btn pointer-events-none">{{ $report->total_units_billed }} Unit</span></td> 
                                <td class="text-zinc-600 font-medium">{{ number_format($report->total_electric_usage) }}</td> 
                                <td class="text-zinc-600 font-medium">{{ number_format($report->total_water_usage) }}</td> 
                                <td class="font-bold text-[#602316]"> 
                                    Rp {{ number_format($report->total_revenue_expected, 0, ',', '.') }} 
                                </td> 
                                <td class="actions"> 
                                    <div class="flex justify-center"> 
                                        <a href="{{ route('reports.pdf', $report->id) }}" class="light-green-btn-action px-4 py-2 flex items-center gap-2 relative z-[999]" download> 
                                            <i class="fa-solid fa-file-pdf"></i> <span>Ekspor PDF</span> 
                                        </a> 
                                    </div> 
                                </td> 
                            </tr> 
                        @empty 
                            <tr> 
                                <td colspan="6" class="p-10 text-center text-zinc-400 italic"> 
                                    Belum ada laporan. Silakan buat laporan baru untuk melihat data. 
                                </td> 
                            </tr> 
                        @endforelse 
                    </tbody> 
                </table> 
            </div> 
        </div> 

        <div class="flex flex-col md:flex-row justify-between items-center gap-4 px-2">
            <div class="text-sm text-zinc-500">
                Showing <span class="text-white">{{ $reports->firstItem() }}</span> 
                to <span class="text-white">{{ $reports->lastItem() }}</span> 
                of <span class="text-white">{{ $reports->total() }}</span> results
            </div>

            <div class="braga-pagination">
                {{ $reports->links('pagination::bootstrap-4') }}
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
        <div class="popup-header">Buat Laporan Bulanan</div> 
        <div class="popup-body"> 
            <form action="{{ route('reports.generate') }}" method="POST"> 
                @csrf 
                <div class="flex flex-col gap-6"> 
                    <div> 
                        <div class="text-field"> 
                            <label class="text-field-label text-left text-zinc-700">Pilih Periode Laporan</label> 
                            <input type="month" name="month" required class="text-field-input [color-scheme:light] cursor-pointer text-zinc-800 border-zinc-300"> 
                        </div> 
                        <p class="text-xs text-zinc-400 italic"> 
                            Pilih periode bulan dan tahun untuk menghitung penggunaan listrik, air, dan estimasi pendapatan secara otomatis. 
                        </p> 
                    </div> 
                    <button type="submit" class="dark-brown-button flex-[2] py-3"> 
                        Buat Sekarang 
                    </button> 
                </div> 
            </form> 
        </div> 
    </div> 
</div> 
@endsection