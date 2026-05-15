@extends('layouts.app') 

@section('content') 
<div class="min-h-screen"> 
    <div class="mb-10 flex flex-col md:flex-row md:items-end justify-between gap-4 pb-8"> 
        <div> 
            <h1 class="title-text">Log Audit</h1> 
            <p class="subtitle-text">Manajemen Riwayat Aktivitas Braga8</p> 
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
        <div class="toolbar">
            <form method="GET" action="{{ route('audit_logs.index') }}" class="flex items-center gap-2 relative w-full md:w-auto">
                <div class="search-wrapper">
                    <input type="text" name="search" placeholder="Cari aktivitas.." value="{{ request('search') }}">
                    <span><i class="fa-solid fa-magnifying-glass"></i></span>
                </div>

                <button type="button" class="dark-brown-button btn-small {{ request()->filled('category') || request()->filled('action') ? 'ring-2 ring-amber-500' : '' }}" id="filter-btn-trigger">
                    <i class="fa-solid fa-filter"></i>
                </button>

                <div class="hidden absolute mt-2 z-50 w-[280px] filter-dropdown-container p-5" id="filter-dropdown" style="top: 100%; right: 0;">
                    <div class="flex flex-col gap-5">
                        
                        <div class="flex flex-col gap-3">
                            <div>
                                <label class="text-[10px] font-bold text-zinc-500 uppercase tracking-widest mb-2 block">Jenis Aktivitas</label>
                                <div class="custom-dropdown w-full">
                                    <div class="filter-select-box flex justify-between items-center cursor-pointer">
                                        <span>
                                            @if(request('action') == 'created') Dibuat 
                                            @elseif(request('action') == 'updated') Diperbarui 
                                            @elseif(request('action') == 'deleted') Dihapus 
                                            @else Semua Aktivitas @endif
                                        </span>
                                        <i class="fa-solid fa-chevron-down text-[10px]"></i>
                                    </div>
                                    <div class="dropdown-options filter-options-list shadow-xl">
                                        <div class="option filter-option-item" data-value="">Semua Aktivitas</div>
                                        <div class="option filter-option-item" data-value="created">Dibuat</div>
                                        <div class="option filter-option-item" data-value="updated">Diperbarui</div>
                                        <div class="option filter-option-item" data-value="deleted">Dihapus</div>
                                    </div>
                                    <input type="hidden" name="action" value="{{ request('action') }}">
                                </div>
                            </div>

                            <div>
                                <label class="text-[10px] font-bold text-zinc-500 uppercase tracking-widest mb-2 block">Kategori Data</label>
                                <div class="custom-dropdown w-full">
                                    <div class="filter-select-box flex justify-between items-center cursor-pointer">
                                        <span>{{ request('category') ? ucfirst(str_replace('_', ' ', request('category'))) : 'Semua Kategori' }}</span>
                                        <i class="fa-solid fa-chevron-down text-[10px]"></i>
                                    </div>
                                    <div class="dropdown-options filter-options-list max-h-[200px] overflow-y-auto">
                                        <div class="option filter-option-item" data-value="">Semua Kategori</div>
                                        @foreach($categories as $category)
                                            <div class="option filter-option-item" data-value="{{ $category }}">
                                                {{ ucfirst(str_replace('_', ' ', $category)) }}
                                            </div>
                                        @endforeach
                                    </div>
                                    <input type="hidden" name="category" value="{{ request('category') }}">
                                </div>
                            </div>
                        </div>

                        <div class="flex gap-2">
                            <a href="{{ route('audit_logs.index') }}" class="light-grey-btn-action flex-1 text-center">
                                Reset
                            </a>
                            <button type="submit" class="dark-brown-btn-action flex-1">
                                Terapkan
                            </button>
                        </div>
                    </div>
                </div>
            </form>

        </div>

        <div class="table-wrapper">
            <div class="table-card">
                <div class="table-card-header">
                    <div class="table-card-title">
                        <span class="value">Riwayat Aktivitas Sistem</span>
                    </div>
                    <div class="table-card-meta">
                        {{ $logs->total() }} Total Aktivitas
                    </div>
                </div>

                <div class="overflow-x-auto">
                    <table class="table">
                        <thead>
                            <tr>
                                <th class="w-[20%]">Pengguna</th>
                                <th class="w-[55%]">Detail Aktivitas</th>
                                <th class="w-[25%] text-right">Waktu Kejadian</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($logs as $log)
                            <tr>
                                <td class="text-zinc-300">
                                    {{ $log->user->name ?? 'Sistem' }}
                                </td>

                                <td>
                                    {!! $log->formatted_action !!} 
                                </td>

                                <td class="text-right text-zinc-500 text-sm">
                                    {{ $log->created_at->translatedFormat('d M Y') }} 
                                    <span class="text-zinc-300 mx-1">•</span> 
                                    {{ $log->created_at->format('H:i') }}
                                </td>
                            </tr>
                            @empty
                            <tr>
                                <td colspan="3" class="text-center py-12 text-zinc-400 italic">
                                    <i class="fa-solid fa-clock-rotate-left mb-2 block text-xl"></i>
                                    Belum ada riwayat aktivitas yang tercatat.
                                </td>
                            </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <div class="flex flex-col md:flex-row justify-between items-center gap-4 px-2">
            <div class="text-sm text-zinc-500">
                Menampilkan <span class="text-white">{{ $logs->firstItem() }}</span> 
                sampai <span class="text-white">{{ $logs->lastItem() }}</span> 
                dari <span class="text-white">{{ $logs->total() }}</span> hasil
            </div>

            <div class="braga-pagination">
                {{ $logs->links('pagination::bootstrap-4') }}
            </div>
        </div>
    </div> 
</div> 

<script>
    const filterBtn = document.getElementById('filter-btn-trigger');
    const filterDropdown = document.getElementById('filter-dropdown');

    if (filterBtn && filterDropdown) {
        filterBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            filterDropdown.classList.toggle('hidden');
        });

        document.addEventListener('click', (e) => {
            if (!filterDropdown.contains(e.target) && !filterBtn.contains(e.target)) {
                filterDropdown.classList.add('hidden');
            }
        });
    }

    document.querySelectorAll('.custom-dropdown').forEach(dropdown => {
        const selectBox = dropdown.querySelector('.filter-select-box');
        const optionsList = dropdown.querySelector('.filter-options-list');
        const hiddenInput = dropdown.querySelector('input[type="hidden"]');
        const displaySpan = selectBox.querySelector('span');

        selectBox.addEventListener('click', (e) => {
            e.stopPropagation();
            document.querySelectorAll('.filter-options-list').forEach(list => {
                if(list !== optionsList) list.classList.add('hidden'); 
            });
            optionsList.classList.toggle('hidden');
            dropdown.classList.toggle('active');
        });

        dropdown.querySelectorAll('.filter-option-item').forEach(option => {
            option.addEventListener('click', () => {
                const value = option.getAttribute('data-value');
                const text = option.textContent;

                displaySpan.textContent = text;
                hiddenInput.value = value;     
                
                optionsList.classList.add('hidden');
                dropdown.classList.remove('active');
            });
        });
    });

    document.addEventListener('click', () => {
        document.querySelectorAll('.filter-options-list').forEach(list => list.classList.add('hidden'));
        document.querySelectorAll('.custom-dropdown').forEach(d => d.classList.remove('active'));
    });
</script>
@endsection