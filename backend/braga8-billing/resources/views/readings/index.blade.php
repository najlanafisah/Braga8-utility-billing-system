@extends('layouts.app') 

@section('content') 
<div class="min-h-screen"> 
    <div class="mb-10 flex flex-col md:flex-row md:items-end justify-between gap-4 pb-8"> 
        <div> 
            <h1 class="title-text">Catatan Meteran</h1> 
            <p class="subtitle-text">Manajemen Penagihan Utilitas Braga8</p> 
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
        @if (session('status')) 
            @php 
            $alerts = [ 
                'reading-confirmed' => [ 
                    'title' => 'Status Diperbarui!', 
                    'desc'  => 'Data meteran telah berhasil dikonfirmasi.', 
                    'icon'  => 'fa-square-check' 
                ], 
                'reading-stored' => [ 
                    'title' => 'Berhasil!', 
                    'desc'  => 'Data meteran baru telah disimpan.', 
                    'icon'  => 'fa-circle-check' 
                ],
            ]; 
            $statusKey = session('status'); 
            $current = $alerts[$statusKey] ?? null; 
            @endphp 

            @if ($current) 
            <div id="universal-alert" class="fixed top-6 right-6 z-[9999] flex items-center justify-between p-5 min-w-[380px] text-white border border-white/20 rounded-2xl backdrop-blur-md shadow-[0_10px_40px_rgba(0,0,0,0.5)] transition-all duration-500" style="background-color: rgba(96, 35, 22, 0.6);"> 
                <div class="flex items-center gap-4"> 
                    <div class="flex items-center justify-center w-11 h-11 rounded-xl bg-white/10 border border-white/10 shadow-inner"> 
                        <i class="fa-solid {{ $current['icon'] }} text-[#FA8327] text-lg"></i> 
                    </div> 
                    <div class="flex flex-col gap-0.5"> 
                        <p class="text-sm font-bold tracking-wide">{{ $current['title'] }}</p> 
                        <p class="text-xs text-white/50 font-light">{{ $current['desc'] }}</p> 
                    </div> 
                </div> 
                <button type="button" onclick="closeUniversalAlert()" class="p-2 text-white/20 hover:text-[#FA8327] transition-colors"> 
                    <i class="fa-solid fa-xmark text-lg"></i> 
                </button> 
            </div> 
            <script> 
                function closeUniversalAlert() { 
                    const alert = document.getElementById('universal-alert'); 
                    if (alert) { 
                        alert.style.opacity = '0'; 
                        alert.style.transform = 'translateX(30px)'; 
                        setTimeout(() => alert.remove(), 500); 
                    } 
                } 
                setTimeout(closeUniversalAlert, 4500); 
            </script> 
            @endif 
        @endif 

        <div class="toolbar mb-6"> 
            <form action="{{ route('meter-readings.index') }}" method="GET" class="search-wrapper"> 
                <input type="text" name="search" value="{{ request('search') }}" placeholder="Cari Penghuni / Unit..."> 
                <i class="fa-solid fa-magnifying-glass"></i> 
            </form> 
        </div> 

        <div class="table-wrapper"> 
            @forelse($tenants as $tenant) 
            <div class="table-card mb-8"> 
                <div class="table-card-header"> 
                    <div class="table-card-title"> 
                        <span class="label">Penghuni:</span> 
                        <span class="value">{{ $tenant->tenant_name }}</span> 
                    </div> 
                    <div class="table-card-meta"> 
                        {{ $tenant->units->count() }} Unit 
                    </div> 
                </div> 
                <table class="table"> 
                    <thead> 
                        <tr> 
                            <th>Unit</th> 
                            <th>No. Meteran</th> 
                            <th>Tipe</th> 
                            <th>Nilai Catat</th> 
                            <th>Petugas</th> 
                            <th class="text-center">Konfirmasi</th> 
                            <th>Tanggal</th> 
                            <th class="text-center">Aksi</th> 
                        </tr> 
                    </thead> 
                    <tbody> 
                        @php $anyReading = false; @endphp 
                        @foreach($tenant->units as $unit) 
                            @foreach($unit->meters as $meter) 
                                @forelse($meter->readings as $reading) 
                                    @php $anyReading = true; @endphp 
                                    <tr> 
                                        <td>{{ $unit->unit_number }}</td> 
                                        <td>{{ $meter->meter_number }}</td> 
                                        <td> 
                                            @if($meter->meter_type == 'electricity') 
                                                <span class="dark-green-btn">Listrik</span> 
                                            @else 
                                                <span class="blue-btn">Air</span> 
                                            @endif 
                                        </td> 
                                        <td>{{ number_format($reading->reading_value, 2) }}</td> 
                                        <td>{{ $reading->user->name }}</td> 
                                        <td class="text-center"> 
                                            <form action="{{ route('meter-readings.update-status', $reading->id) }}" method="POST"> 
                                                @csrf 
                                                @method('PATCH') 
                                                <button type="submit" style="background: none; border: none; cursor: pointer;"> 
                                                    @if($reading->status === 'checked') 
                                                        <i class="fa-solid fa-square-check text-emerald-500 text-xl"></i> 
                                                    @else 
                                                        <i class="fa-regular fa-square text-zinc-500 text-xl"></i> 
                                                    @endif 
                                                </button> 
                                            </form> 
                                        </td> 
                                        <td>{{ \Carbon\Carbon::parse($reading->recorded_at)->format('d M Y') }}</td> 
                                        <td> 
                                            <div class="flex justify-center"> 
                                                @if($reading->photo_path) 
                                                    <button class="light-green-btn-action" data-popup="photoModal" onclick="showImage('{{ asset('storage/'.$reading->photo_path) }}', '{{ $unit->unit_number }}')"> 
                                                        <i class="fa-regular fa-eye"></i> Lihat Foto 
                                                    </button> 
                                                @else 
                                                    <span class="subtitle-text text-xs">Tanpa Foto</span> 
                                                @endif 
                                            </div> 
                                        </td> 
                                    </tr> 
                                @empty 
                                @endforelse 
                            @endforeach 
                        @endforeach 
                        
                        @if(!$anyReading) 
                        <tr> 
                            <td colspan="8" class="text-center py-8"> 
                                <div class="flex flex-col items-center opacity-50"> 
                                    <i class="fa-solid fa-folder-open text-2xl mb-2"></i> 
                                    <p class="subtitle-text">Belum ada data meter untuk penghuni ini.</p> 
                                </div> 
                            </td> 
                        </tr> 
                        @endif 
                    </tbody> 
                </table> 
            </div> 
            @empty 
            <div class="flex flex-col items-center justify-center py-20 bg-white/5 border border-white/10 rounded-3xl"> 
                <i class="fa-solid fa-gauge-high text-4xl text-zinc-600 mb-4"></i> 
                <h3 class="text-zinc-600 font-semibold">Data Tidak Ditemukan</h3> 
            </div> 
            @endforelse 
        </div> 
    </div> 
</div> 

<div class="popup" id="photoModal"> 
    <div class="popup-overlay"></div> 
    <div class="popup-card popup-md"> 
        <div class="popup-close-wrapper"> 
            <button class="popup-close" data-close="photoModal"> 
                <i class="fa-solid fa-xmark"></i> 
            </button> 
        </div> 
        <div class="popup-header"> 
            <h2 id="modalUnitTitle">Unit -</h2> 
            <p class="subtitle-text">Bukti Foto Meteran</p> 
        </div>
        <div class="popup-body flex flex-col items-center gap-4 mt-4">             
            <a id="modalImageLink" href="#" target="_blank" class="w-full group relative cursor-zoom-in"> 
                <div class="w-full bg-zinc-900 rounded-2xl border border-white/20 overflow-hidden flex justify-center items-center" style="max-height: 300px;"> 
                    <img id="modalImage" src="" alt="Meter Reading" class="max-w-full max-h-[450px] object-contain transition-transform duration-300 group-hover:scale-[1.02]"> 
                </div> 
                <div class="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity bg-black/20 rounded-2xl"> 
                    <i class="fa-solid fa-magnifying-glass-plus text-white text-2xl"></i> 
                </div> 
            </a> 

            <button class="light-grey-btn w-full" data-close="photoModal">Tutup</button> 
        </div> 
    </div> 
</div> 

<script> 
    function showImage(src, unit) { 
        document.getElementById('modalImage').src = src; 
        document.getElementById('modalImageLink').href = src; 
        document.getElementById('modalUnitTitle').innerText = "Unit " + unit; 
    } 
</script> 
@endsection