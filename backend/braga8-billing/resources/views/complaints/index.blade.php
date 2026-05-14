@extends('layouts.app')

@section('content')
<div class="min-h-screen">
    <div class="mb-10 flex flex-col md:flex-row md:items-end justify-between gap-4 pb-8">
        <div>
            <h1 class="title-text">Complaints</h1>
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
        @if (session('status'))
            @php
                $alerts = [
                    'complaint-resolved' => ['title' => 'Berhasil!', 'desc' => 'Solusi telah disimpan.', 'icon' => 'fa-circle-check'],
                    'complaint-deleted'  => ['title' => 'Data Dihapus!', 'desc' => 'Laporan telah dihapus.', 'icon' => 'fa-trash-can']
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

        <div class="toolbar">
            <form method="GET" action="{{ route('complaints.index') }}" class="flex items-center gap-2">
                <div class="search-wrapper">
                    <input type="text" name="search" placeholder="Search Complaint.." value="{{ request('search') }}">
                    <span><i class="fa-solid fa-magnifying-glass"></i></span>
                </div>
            </form>
            <div class="toolbar-action">
                <button class="dark-brown-button btn-small">
                    <span><i class="fa-solid fa-filter"></i></span>
                    <span>Newest to Oldest</span>
                </button>
            </div>
        </div>

        <div class="table-wrapper">
            <div class="table-card">
                <div class="table-card-header">
                    <div class="table-card-title">
                        <span class="value">Daftar Laporan Keluhan</span>
                    </div>
                </div>
                <table class="table">
                    <thead>
                        <tr>
                            <th>No</th>
                            <th>Pelapor</th>
                            <th>Peran</th>
                            <th>Tanggal</th>
                            <th>Status</th>
                            <th class="text-center">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($complaints as $index => $complaint)
                            <div class="popup" id="view-complaint-{{ $complaint->id }}">
                                <div class="popup-overlay"></div>
                                <div class="popup-card popup-lg text-left">
                                    <div class="popup-close-wrapper">
                                        <button class="popup-close" data-close="view-complaint-{{ $complaint->id }}">
                                            <i class="fa-solid fa-xmark"></i>
                                        </button>
                                    </div>
                                    <div class="popup-header">{{ $complaint->subject ?? 'Keluhan Umum' }}</div>
                                    
                                    <div class="popup-body flex flex-col gap-6 pt-2">
                                        <div class="flex flex-col lg:flex-row gap-8">
                                            <div class="flex-1 flex flex-col gap-6">
                                                <div class="grid grid-cols-2 gap-y-5 gap-x-4">
                                                    <div class="detail-item">
                                                        <p>Yang melapor</p>
                                                        <p>{{ $complaint->reported_by }}</p>
                                                    </div>
                                                    <div class="detail-item">
                                                        <p>Peran</p>
                                                        <p>{{ ucfirst($complaint->role) }}</p>
                                                    </div>
                                                    <div class="detail-item">
                                                        <p>Tanggal</p>
                                                        <p>{{ $complaint->report_date->format('d F Y') }}</p>
                                                    </div>
                                                    <div class="detail-item">
                                                        <p>Status</p>
                                                        <div>
                                                            @if($complaint->status === 'resolved')
                                                                <span class="dark-green-btn">Solved</span>
                                                            @else
                                                                <span class="red-btn">Unsolved</span>
                                                            @endif
                                                        </div>
                                                    </div>
                                                </div>

                                                <div class="bg-white/5 border border-white/10 p-5 rounded-2xl backdrop-blur-sm">
                                                    <label class="block text-[10px] font-bold text-zinc-500 uppercase tracking-widest mb-3">Detail Keluhan</label>
                                                    <p class="text-zinc-300 text-sm leading-relaxed italic font-light">
                                                        "{{ $complaint->description }}"
                                                    </p>
                                                </div>
                                            </div>

                                            @if($complaint->image)
                                            <div class="w-full lg:w-[220px] flex flex-col gap-2">
                                                <label class="block text-[10px] font-bold text-zinc-500 uppercase tracking-widest text-center lg:text-left">Evidence</label>
                                                <div class="relative group aspect-square rounded-2xl overflow-hidden border border-white/10 bg-black/20 backdrop-blur-md">                                                    
                                                    <img src="{{ asset('storage/' . $complaint->image) }}" class="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110" onclick="window.open(this.src, '_blank')">
                                                    <div class="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center pointer-events-none">
                                                        <i class="fa-solid fa-magnifying-glass-plus text-white text-xl cursor-zoom-in"></i>
                                                    </div>
                                                </div>
                                            </div>
                                            @endif
                                        </div>

                                        <div class="border-t border-white/5 pt-6">
                                            @if($complaint->status !== 'resolved')
                                                <form action="{{ route('complaints.action', $complaint->id) }}" method="POST" class="flex flex-col gap-4">
                                                    @csrf
                                                    <div class="flex flex-col gap-6">
                                                        <div class="flex flex-col gap-2 group">
                                                            <label class="block text-[10px] font-bold text-zinc-400 uppercase tracking-widest">Input Resolution</label>
                                                            <textarea name="solution" class="w-full bg-white/5 border border-white/10 rounded-2xl px-5 py-4 text-white text-sm placeholder:text-zinc-600 focus:outline-none focus:border-[#FA8327]/50 focus:bg-white/[0.08] transition-all min-h-[100px] resize-none" placeholder="Tulis langkah penyelesaian di sini..." required>{{ old('solution', $complaint->solution) }}</textarea>
                                                        </div>
                                                        <button type="submit" class="dark-brown-button w-full">
                                                            Submit Solution
                                                        </button>
                                                    </div>
                                                </form>
                                            @else
                                                <div class="bg-zinc-500/5 border border-zinc-500/20 p-5 rounded-2xl">
                                                    <div class="flex justify-between items-center mb-2">
                                                        <label class="block text-[10px] font-bold text-zinc-400 uppercase tracking-widest">Resolution Note</label>
                                                        <span class="text-[9px] text-zinc-500">Updated {{ $complaint->updated_at->diffForHumans() }}</span>
                                                    </div>
                                                    <p class="text-zinc-300 text-sm font-light leading-relaxed">
                                                        {{ $complaint->solution ?? 'Keluhan ini telah diselesaikan.' }}
                                                    </p>
                                                </div>
                                            @endif
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <tr>
                                <td>{{ $complaints->firstItem() + $index }}</td>
                                <td class="font-bold text-zinc-800">{{ $complaint->reported_by }}</td>
                                <td>{{ ucfirst($complaint->role) }}</td>
                                <td>{{ $complaint->report_date->format('d M Y') }}</td>
                                <td>
                                    @if($complaint->status === 'resolved')
                                        <span class="dark-green-btn">Resolved</span>
                                    @else
                                        <span class="amber-btn">Unsolved</span>
                                    @endif
                                </td>
                                <td class="actions">
                                    <div class="flex justify-center gap-2">
                                        <button class="light-green-btn-action" data-popup="view-complaint-{{ $complaint->id }}">
                                            <i class="fa-solid fa-eye"></i>
                                            <span class="">Buka</span>
                                        </button>
                                        <form id="delete-form-{{ $complaint->id }}" action="{{ route('complaints.destroy', $complaint->id) }}" method="POST" class="m-0 p-0">
                                            @csrf
                                            @method('DELETE')
                                            <button type="button" class="dark-brown-btn-action border-0" data-popup="delete-complaint" data-id="{{ $complaint->id }}">
                                                <i class="fa-solid fa-trash "></i>
                                                <span class="">Hapus</span>
                                            </button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="6" class="text-center py-10 text-zinc-400 font-medium">No complaints found.</td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>

        <div class="flex flex-col md:flex-row justify-between items-center gap-4 mt-6 px-2">
            <div class="text-sm text-zinc-500">
                Showing <span class="text-white">{{ $complaints->firstItem() }}</span> to <span class="text-white">{{ $complaints->lastItem() }}</span> of <span class="text-white">{{ $complaints->total() }}</span> results
            </div>
            <div class="braga-pagination">
                {{ $complaints->links() }}
            </div>
        </div>
    </div>

    <div class="popup" id="delete-complaint">
        <div class="popup-overlay"></div>
        <div class="popup-card popup-md">
            <div class="popup-close-wrapper">
                <button class="popup-close" data-close="delete-complaint">
                    <i class="fa-solid fa-xmark"></i>
                </button>
            </div>
            <div class="popup-header text-[#602316]">Hapus Laporan Keluhan</div>
            <div class="popup-body flex flex-col gap-6 text-center">
                <div class="flex gap-4 justify-center">
                    <button type="button" id="confirm-delete-btn" class="light-brown-btn px-10">Ya</button>
                    <button type="button" class="dark-brown-button px-10" data-close="delete-complaint">Batal</button>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection