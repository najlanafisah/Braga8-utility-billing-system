@extends('layouts.app')

@section('content')
<div class="min-h-screen">
    <div class="mb-10 flex flex-col md:flex-row md:items-end justify-between gap-4 pb-8">
        <div>
            <h1 class="title-text">Pengaturan Siklus</h1>
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
        {{-- Alert System --}}
        @if (session('status'))
            @php
                $alerts = [
                    'reminder-stored'  => [ 'title' => 'Berhasil Dibuat!', 'desc'  => 'Pengingat baru telah dijadwalkan.', 'icon'  => 'fa-circle-check' ],
                    'reminder-updated' => [ 'title' => 'Berhasil Update!', 'desc'  => 'Perubahan data pengingat telah disimpan.', 'icon'  => 'fa-pen' ],
                    'reminder-deleted' => [ 'title' => 'Data Dihapus!', 'desc'  => 'Pengingat tersebut telah berhasil dihapus.', 'icon'  => 'fa-trash-can' ]
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
            @endif
        @endif

        <div class="toolbar">
            <form method="GET" action="{{ route('reminders.index') }}" class="flex items-center gap-2">
                <div class="search-wrapper">
                    <input type="text" name="search" placeholder="Cari Pengingat.." value="{{ request('search') }}">
                    <span><i class="fa-solid fa-magnifying-glass"></i></span>
                </div>
            </form>
            <div class="toolbar-action">
                <button class="light-brown-btn btn-small" data-popup="add-reminder">
                    <span><i class="fa-solid fa-plus"></i></span>
                    <span>Buat Pengingat Baru</span>
                </button>
            </div>
        </div>

        <div class="table-wrapper">
            <div class="table-card">
                <div class="table-card-header">
                    <div class="table-card-title">
                        <span class="value">Atur Notifikasi</span>
                    </div>
                </div>
                <table class="table">
                    <thead>
                        <tr>
                            <th>No</th>
                            <th>Judul</th>
                            <th>Untuk</th>
                            <th>Tgl Diingatkan</th>
                            <th>Status</th>
                            <th class="text-center">Aksi</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($reminders as $index => $reminder)
                            <tr>
                                <td>{{ $reminders->firstItem() + $index }}</td>
                                <td>{{ $reminder->title }}</td>
                                <td> {{ $reminder->role_target == 'tenant' ? 'Penyewa' : ucfirst($reminder->role_target) }} </td>
                                <td>
                                    <div>{{ \Carbon\Carbon::parse($reminder->reminder_date)->translatedFormat('d M Y') }}</div>
                                </td>
                                <td>
                                    @if($reminder->status === 'pending')
                                        <span class="amber-btn text-[10px]"> Menunggu </span>
                                    @elseif($reminder->status === 'sent')
                                        <span class="blue-btn text-[10px]"> Terkirim </span>
                                    @elseif($reminder->status === 'completed')
                                        <span class="dark-green-btn text-[10px]"> Selesai </span>
                                    @else
                                        <span class="red-btn text-[10px]"> Gagal </span>
                                    @endif
                                </td>
                                <td class="actions">
                                    <div class="flex justify-center gap-2">
                                        <button class="light-brown-btn-action" data-popup="edit-reminder-{{ $reminder->id }}">
                                            <i class="fa-solid fa-pen text-xs"></i> <span class="text-xs">Ubah</span>
                                        </button>
                                        <form id="delete-form-{{ $reminder->id }}" action="{{ route('reminders.destroy', $reminder->id) }}" method="POST" class="m-0 p-0">
                                            @csrf @method('DELETE')
                                            <button type="button" class="dark-brown-btn-action border-0 w-full justify-center btn-trigger-delete" data-popup="delete-reminder-modal" data-id="{{ $reminder->id }}">
                                                <div class="flex items-center gap-2">
                                                    <i class="fa-solid fa-trash text-xs"></i> <span class="text-xs">Hapus</span>
                                                </div>
                                            </button>
                                        </form>
                                    </div>

                                    <div class="popup" id="edit-reminder-{{ $reminder->id }}">
                                        <div class="popup-overlay"></div>
                                        <div class="popup-card popup-md text-left">
                                            <div class="popup-close-wrapper">
                                                <button class="popup-close" data-close="edit-reminder-{{ $reminder->id }}">
                                                    <i class="fa-solid fa-xmark"></i>
                                                </button>
                                            </div>
                                            <div class="popup-header">Edit Pengingat</div>
                                            <div class="popup-body flex flex-col gap-6">
                                                <form action="{{ route('reminders.update', $reminder->id) }}" method="POST" class="space-y-6">
                                                    @csrf @method('PUT')
                                                    <div class="flex flex-col gap-6">
                                                        <div>
                                                            <div class="text-field">
                                                                <label class="text-field-label">Judul</label>
                                                                <input type="text" name="title" value="{{ old('title', $reminder->title) }}" class="text-field-input" required>
                                                            </div>
                                                            <div class="grid grid-cols-2 gap-4">
                                                                <div class="text-field">
                                                                    <label class="text-field-label">Target Role</label>
                                                                    <div class="custom-dropdown">
                                                                        <div class="dropdown-selected">
                                                                            <span class="placeholder text-[#131316]">{{ $reminder->role_target == 'tenant' ? 'Penyewa' : ucfirst($reminder->role_target) }}</span>
                                                                            <i class="fa-solid fa-chevron-down text-[10px]" style="color: #131316;"></i>
                                                                        </div>
                                                                        <div class="dropdown-options">
                                                                            <div class="option" data-value="admin">Admin</div>
                                                                            <div class="option" data-value="supervisor">Supervisor</div>
                                                                            <div class="option" data-value="tenant">Penyewa</div>
                                                                            <div class="option" data-value="petugas">Petugas</div>
                                                                        </div>
                                                                        <input type="hidden" name="role_target" value="{{ $reminder->role_target }}" required>
                                                                    </div>
                                                                </div>
                                                                <div class="text-field">
                                                                    <label class="text-field-label">Status</label>
                                                                    <div class="custom-dropdown">
                                                                        <div class="dropdown-selected">
                                                                            <span class="placeholder text-[#131316]">
                                                                                @if($reminder->status == 'pending') Menunggu @elseif($reminder->status == 'sent') Terkirim @else Selesai @endif
                                                                            </span>
                                                                            <i class="fa-solid fa-chevron-down text-[10px]" style="color: #131316;"></i>
                                                                        </div>
                                                                        <div class="dropdown-options">
                                                                            <div class="option" data-value="pending">Menunggu</div>
                                                                            <div class="option" data-value="sent">Terkirim</div>
                                                                            <div class="option" data-value="completed">Selesai</div>
                                                                        </div>
                                                                        <input type="hidden" name="status" value="{{ $reminder->status }}" required>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div class="grid grid-cols-2 gap-4">
                                                                <div class="text-field">
                                                                    <label class="text-field-label">Tgl Diingatkan</label>
                                                                    <input type="date" name="reminder_date" value="{{ \Carbon\Carbon::parse($reminder->reminder_date)->format('Y-m-d') }}" class="text-field-input" required>
                                                                </div>
                                                                <div class="text-field">
                                                                    <label class="text-field-label">Tenggat Waktu</label>
                                                                    <input type="date" name="due_date" value="{{ \Carbon\Carbon::parse($reminder->due_date)->format('Y-m-d') }}" class="text-field-input" required>
                                                                </div>
                                                            </div>
                                                        </div>
                                                        <button type="submit" class="dark-brown-button">Simpan Perubahan</button>
                                                    </div>
                                                </form>
                                            </div>
                                        </div>
                                    </div>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="6" class="text-center py-10 text-zinc-400"> Tidak ada pengingat yang ditemukan. </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>

        <div class="flex flex-col md:flex-row justify-between items-center gap-4 px-2">
            <div class="text-sm text-zinc-500">
                Menampilkan <span class="text-white">{{ $reminders->firstItem() }}</span> sampai <span class="text-white">{{ $reminders->lastItem() }}</span> dari <span class="text-white">{{ $reminders->total() }}</span> hasil
            </div>
            <div class="braga-pagination">
                {{ $reminders->links('pagination::bootstrap-4') }}
            </div>
        </div>
    </div>

    <div class="popup" id="add-reminder">
        <div class="popup-overlay"></div>
        <div class="popup-card popup-md text-left">
            <div class="popup-close-wrapper">
                <button class="popup-close"><i class="fa-solid fa-xmark"></i></button>
            </div>
            <div class="popup-header">Tambah Pengingat Baru</div>
            <div class="popup-body">
                <form action="{{ route('reminders.store') }}" method="POST">
                    @csrf
                    <div class="flex flex-col gap-6">
                        <div class="space-y-5">
                            <div class="text-field">
                                <label class="text-field-label">Judul</label>
                                <input type="text" name="title" class="text-field-input" placeholder="Misal: Tagihan Listrik Maret" required>
                            </div>
                            <div class="text-field">
                                <label class="text-field-label">Target Role</label>
                                <div class="custom-dropdown">
                                    <div class="dropdown-selected">
                                        <span class="placeholder">Pilih Role</span>
                                        <i class="fa-solid fa-chevron-down text-[10px]"></i>
                                    </div>
                                    <div class="dropdown-options">
                                        <div class="option" data-value="admin">Admin</div>
                                        <div class="option" data-value="supervisor">Supervisor</div>
                                        <div class="option" data-value="tenant">Penyewa</div>
                                        <div class="option" data-value="petugas">Petugas</div>
                                    </div>
                                    <input type="hidden" name="role_target" required>
                                </div>
                            </div>
                            <div class="grid grid-cols-2 gap-4">
                                <div class="text-field">
                                    <label class="text-field-label">Tgl Diingatkan</label>
                                    <input type="date" name="reminder_date" class="text-field-input" required>
                                </div>
                                <div class="text-field">
                                    <label class="text-field-label">Tenggat Waktu</label>
                                    <input type="date" name="due_date" class="text-field-input" required>
                                </div>
                            </div>
                            <div class="flex items-start gap-3 p-4 bg-white/5 border border-white/10 rounded-xl transition-all hover:bg-white/10">
                                <div class="mt-1">
                                    <input type="checkbox" name="auto_escalate" id="auto_escalate" value="1" class="w-5 h-5 rounded border-zinc-600 text-[#a04d30] focus:ring-[#a04d30] bg-zinc-800">
                                </div>
                                <label for="auto_escalate" class="cursor-pointer">
                                    <span class="text-white font-semibold text-sm block">Otomatis buat 3 tahap eskalasi</span>
                                    <span class="text-zinc-500 text-xs leading-relaxed">(Teguran 1, 2, & Terakhir). Khusus untuk target Penyewa.</span>
                                </label>
                            </div>
                        </div>
                        <button type="submit" class="dark-brown-button w-full">Pasang Pengingat</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <div class="popup" id="delete-reminder-modal">
        <div class="popup-overlay"></div>
        <div class="popup-card popup-md text-center">
            <div class="popup-close-wrapper">
                <button class="popup-close"><i class="fa-solid fa-xmark"></i></button>
            </div>
            <div class="popup-header">Hapus Pengingat Ini?</div>
            <div class="popup-body">
                <div class="btn-delete-wrapper flex gap-4">
                    <button id="confirm-delete-btn" class="light-brown-btn flex-1">Ya, Hapus</button>
                    <button class="dark-brown-button flex-1" data-close="delete-reminder-modal">Batal</button>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection