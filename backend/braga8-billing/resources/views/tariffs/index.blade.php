@extends('layouts.app')

@section('content')
<div class="min-h-screen">
    <div class="mb-10 flex flex-col md:flex-row md:items-end justify-between gap-4 border-zinc-200 pb-8">
        <div>
            <h1 class="title-text">Pengaturan Tarif</h1>
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
                    'tariff-stored'  => [
                        'title' => 'Berhasil Simpan!',
                        'desc'  => 'Tariff baru telah ditambahkan ke sistem.',
                        'icon'  => 'fa-circle-check'
                    ],
                    'tariff-updated' => [
                        'title' => 'Berhasil Update!',
                        'desc'  => 'Perubahan data tariff telah disimpan.',
                        'icon'  => 'fa-pen-to-square'
                    ],
                    'tariff-deleted' => [
                        'title' => 'Data Dihapus!',
                        'desc'  => 'Tariff tersebut telah berhasil dihapus.',
                        'icon'  => 'fa-trash-can'
                    ],
                    'profile-updated' => [
                        'title' => 'Profil Diperbarui!',
                        'desc'  => 'Informasi akun kamu sudah berhasil diubah.',
                        'icon'  => 'fa-user-check'
                    ]
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
            <form action="{{ route('tariffs.index') }}" method="GET" class="search-wrapper">
                <input type="text" name="search" value="{{ request('search') }}" placeholder="Cari Jenis Tarif..">
                <span><i class="fa-solid fa-magnifying-glass"></i></span>
            </form>

            <div class="toolbar-action">
                <button class="light-brown-btn btn-small" data-popup="add-new-tariff">
                    <span><i class="fa-solid fa-plus"></i></span>
                    <span>Tambah Jenis Tarif Baru</span>
                </button>
            </div>
        </div>

        <div class="table-wrapper">
            @forelse($tariffs as $tariff)
                <div class="popup" id="detail-tariff-{{ $tariff->id }}">
                    <div class="popup-overlay"></div>

                        <div class="popup-card popup-md">
                            <div class="popup-close-wrapper">
                                <button class="popup-close" data-close="detail-tariff-{{ $tariff->id }}">
                                    <i class="fa-solid fa-xmark"></i>
                                </button>
                            </div>
                            
                            <div class="popup-header">{{ $tariff->name ?? 'Unnamed Tariff' }}</div>
                            
                            <div class="popup-body user-detail-info flex flex-col gap-4">
                                <div class="flex justify-between">
                                    <div class="flex flex-col gap-4">
                                        <div class="flex flex-col gap-2">
                                            <div class="detail-item">
                                                <p>Harga Air</p>
                                                <p>Rp {{ number_format($tariff->water_price, 0, ',', '.') }}</p>
                                            </div>
                                            <div class="detail-item">
                                                <p>Harga Listrik</p>
                                                <p>Rp {{ number_format($tariff->electric_price, 0, ',', '.') }}</p>
                                            </div>
                                            <div class="detail-item">
                                                <p>Tarif Pajak</p>
                                                <p>{{ $tariff->tax_percent }}%</p>
                                            </div>
                                        </div>
                                    </div>

                                    <div class="flex flex-col gap-4">
                                        <div class="flex flex-col gap-2">
                                            <div class="detail-item">
                                                <p>Beban Listrik</p>
                                                <p>Rp {{ number_format($tariff->other_fees['electric_load'] ?? 0, 0, ',', '.') }}</p>
                                            </div>
                                            <div class="detail-item">
                                                <p>Perawatan</p>
                                                <p>Rp {{ number_format($tariff->other_fees['maintenance'] ?? 0, 0, ',', '.') }}</p>
                                            </div>
                                            <div class="detail-item">
                                                <p>Biaya Administrasi</p>
                                                <p>Rp {{ number_format($tariff->other_fees['admin_fee'] ?? 0, 0, ',', '.') }}</p>
                                            </div>
                                            <div class="detail-item">
                                                <p>Pajak Materai</p>
                                                <p>Rp {{ number_format($tariff->other_fees['stamp_fee'] ?? 0, 0, ',', '.') }}</p>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                @if(!empty($tariff->other_fees) && count($tariff->other_fees) > 4)
                                    <div class="border-t border-zinc-100">
                                        <p class="font-bold text-zinc-400 text-[12px] uppercase tracking-widest pt-2">Biaya Tambahan</p>
                                        <div class="grid grid-cols-1 gap-2">
                                            @foreach($tariff->other_fees as $key => $value)
                                                @if(!in_array($key, ['electric_load', 'maintenance', 'admin_fee', 'stamp_fee', 'tax_percent']))
                                                    <div class="detail-item">
                                                        <p class="capitalize">{{ str_replace('_', ' ', $key) }}</p>
                                                        <p>Rp {{ number_format($value, 0, ',', '.') }}</p>
                                                    </div>
                                                @endif
                                            @endforeach
                                        </div>
                                    </div>
                                @endif
                            </div>
                            
                            <div class="mt-6 flex justify-between items-center text-[12px] text-zinc-400">
                                <p>ID: #TRF-{{ $tariff->id }}</p>
                                <p>Terakhir Diperbarui: {{ $tariff->updated_at->format('d M Y') }}</p>
                            </div>
                        </div>
                </div>

                <div class="popup" id="update-tariff-{{ $tariff->id }}">
                    <div class="popup-overlay"></div>
                    <div class="popup-card popup-md">
                        <div class="popup-close-wrapper">
                            <button class="popup-close" data-close="update-tariff-{{ $tariff->id }}">
                                <i class="fa-solid fa-xmark"></i>
                            </button>
                        </div>
                        <div class="popup-header">Edit Tarif: {{ $tariff->name }}</div>
                        
                        <form action="{{ route('tariffs.update', $tariff->id) }}" method="POST">
                            @csrf
                            @method('PUT')
                            <div class="popup-body flex flex-col gap-6">
                                <div>
                                    <div class="text-field">
                                        <label class="text-field-label">Nama Tarif</label>
                                        <input type="text" name="name" class="text-field-input" value="{{ old('name', $tariff->name) }}" required>
                                    </div>
                                    
                                    <div class="add-tariff-wrapper">
                                        <div class="column">
                                            <div class="text-field">
                                                <label class="text-field-label">Biaya Listrik (per kWh)</label>
                                                <input type="number" name="electric_price" class="text-field-input" step="0.01" value="{{ old('electric_price', $tariff->electric_price) }}" required>
                                            </div>
                                            <div class="text-field">
                                                <label class="text-field-label">Biaya Beban Listrik</label>
                                                <input type="number" name="other_fees[electric_load]" class="text-field-input" step="0.01" value="{{ old('other_fees.electric_load', $tariff->other_fees['electric_load'] ?? 0) }}">
                                            </div>
                                            <div class="text-field">
                                                <label class="text-field-label">Biaya Administrasi</label>
                                                <input type="number" name="other_fees[admin_fee]" class="text-field-input" step="0.01" value="{{ old('other_fees.admin_fee', $tariff->other_fees['admin_fee'] ?? 0) }}">
                                            </div>
                                            <div class="text-field">
                                                <label class="text-field-label">Persentase Pajak (%)</label>
                                                <input type="number" name="tax_percent" class="text-field-input" step="0.01" value="{{ old('tax_percent', $tariff->tax_percent) }}">
                                            </div>
                                        </div>
                                        <div class="column">
                                            <div class="text-field">
                                                <label class="text-field-label">Biaya Air (per m³)</label>
                                                <input type="number" name="water_price" class="text-field-input" step="0.01" value="{{ old('water_price', $tariff->water_price) }}" required>
                                            </div>
                                            <div class="text-field">
                                                <label class="text-field-label">Pemeliharaan</label>
                                                <input type="number" name="other_fees[maintenance]" class="text-field-input" step="0.01" value="{{ old('other_fees.maintenance', $tariff->other_fees['maintenance'] ?? 0) }}">
                                            </div>
                                            <div class="text-field">
                                                <label class="text-field-label">Biaya Materai</label>
                                                <input type="number" name="other_fees[stamp_fee]" class="text-field-input" step="0.01" value="{{ old('other_fees.stamp_fee', $tariff->other_fees['stamp_fee'] ?? 0) }}">
                                            </div>
                                            <div class="text-field">
                                                <label class="text-field-label">Biaya Lainnya</label>
                                                <input type="number" name="other_fees[other_fee]" class="text-field-input" step="0.01" value="{{ old('other_fees.other_fee', $tariff->other_fees['other_fee'] ?? 0) }}">
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <button type="submit" class="dark-brown-button">
                                    Perbarui Data Tarif
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
        
                <div class="table-card mb-4">
                    <div class="table-card-header">
                        <div class="table-card-title">
                            <span class="label">Nama Tarif:</span>
                            <span class="value">{{ $tariff->name ?? 'Unnamed Tariff' }}</span>
                        </div>
                    </div>

                    <div class="table-responsive">
                        <table class="table">
                            <thead>
                                <tr>
                                    <th>Harga Air</th>
                                    <th>Harga Listrik</th>
                                    <th>Beban Listrik</th> 
                                    <th>Pemeliharaan</th>
                                    <th>Biaya Administrasi</th>
                                    <th>Tindakan</th>
                                </tr>
                            </thead>

                            <tbody>
                                <tr>
                                    <td>Rp {{ number_format($tariff->water_price, 0, ',', '.') }}</td>
                                    <td>Rp {{ number_format($tariff->electric_price, 0, ',', '.') }}</td>                                
                                    <td>Rp {{ number_format($tariff->other_fees['electric_load'] ?? 0, 0, ',', '.') }}</td>
                                    <td>Rp {{ number_format($tariff->other_fees['maintenance'] ?? 0, 0, ',', '.') }}</td>
                                    <td>Rp {{ number_format($tariff->other_fees['admin_fee'] ?? 0, 0, ',', '.') }}</td>                                    
                                    <td class="actions">
                                        <div class="grid grid-cols-3 gap-2 w-full">
                                            
                                            <button type="button" class="light-green-btn-action w-full justify-center" data-popup="detail-tariff-{{ $tariff->id }}">
                                                <div class="flex items-center gap-2">
                                                    <i class="fa-solid fa-eye text-xs"></i>
                                                    <span class="text-xs">Lihat</span>
                                                </div>
                                            </button>
                                            
                                            <button type="button" class="light-brown-btn-action w-full justify-center" data-popup="update-tariff-{{ $tariff->id }}">
                                                <div class="flex items-center gap-2">
                                                    <i class="fa-solid fa-pen text-xs"></i>
                                                    <span class="text-xs">Edit</span>
                                                </div>
                                            </button>

                                            <form id="delete-form-{{ $tariff->id }}" 
                                                action="{{ route('tariffs.destroy', $tariff->id) }}" 
                                                method="POST" 
                                                class="m-0 p-0 w-full">
                                                @csrf 
                                                @method('DELETE')
                                                <button type="button" 
                                                        class="dark-brown-btn-action border-0 w-full justify-center" 
                                                        data-popup="delete-tariff" 
                                                        data-id="{{ $tariff->id }}">
                                                    <div class="flex items-center gap-2">
                                                        <i class="fa-solid fa-trash text-xs"></i>
                                                        <span class="text-xs">Hapus</span>
                                                    </div>
                                                </button>
                                            </form>

                                        </div>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            @empty
            <div class="table-card p-10 text-center text-zinc-400 italic">
                Data tarif tidak ditemukan
            </div>
            @endforelse
        </div>
    </div>

    <div class="popup" id="add-new-tariff">
        <div class="popup-overlay"></div>

        <div class="popup-card popup-md">
            <div class="popup-close-wrapper">
                <button class="popup-close" data-close="add-new-tariff">
                    <i class="fa-solid fa-xmark"></i>
                </button>
            </div>
            <div class="popup-header">Tambah Tarif Baru</div>
            
            <form action="{{ route('tariffs.store') }}" method="POST">
                @csrf
                <div class="popup-body flex flex-col gap-6">
                    <div>
                        <div class="text-field">
                            <label class="text-field-label">Nama Tarif <span class="text-[#FA8327]">*</span></label>
                            <input type="text" name="name" class="text-field-input" placeholder="e.g., Residential Type A" required>
                        </div>

                        <div class="add-tariff-wrapper">
                            <div class="column">
                                <div class="text-field">
                                    <label class="text-field-label">Biaya Listrik (per kWh) <span class="text-[#FA8327]">*</span></label>
                                    <input type="number" name="electric_price" class="text-field-input" step="0.01" placeholder="Contoh: 1500" required>
                                </div>
                                <div class="text-field">
                                    <label class="text-field-label">Biaya Beban Listrik</label>
                                    <input type="number" name="other_fees[electric_load]" class="text-field-input" step="0.01" placeholder="0">
                                </div>
                                <div class="text-field">
                                    <label class="text-field-label">Biaya Administrasi</label>
                                    <input type="number" name="other_fees[admin_fee]" class="text-field-input" step="0.01" placeholder="0">
                                </div>
                                <div class="text-field">
                                    <label class="text-field-label text-blue-600 font-bold">Persentase Pajak (%) <span class="text-[#FA8327]">*</span></label>
                                    <input type="number" name="tax_percent" class="text-field-input border-blue-200" step="0.01" placeholder="0" required>
                                </div>
                            </div>

                            <div class="column">
                                <div class="text-field">
                                    <label class="text-field-label">Biaya Air (per m³) <span class="text-[#FA8327]">*</span></label>
                                    <input type="number" name="water_price" class="text-field-input" step="0.01" placeholder="Contoh: 5000" required>
                                </div>
                                <div class="text-field">
                                    <label class="text-field-label">Pemeliharaan</label>
                                    <input type="number" name="other_fees[maintenance]" class="text-field-input" step="0.01" placeholder="0">
                                </div>
                                <div class="text-field">
                                    <label class="text-field-label">Biaya Materai</label>
                                    <input type="number" name="other_fees[stamp_fee]" class="text-field-input" step="0.01" placeholder="0">
                                </div>
                                <div class="text-field">
                                    <label class="text-field-label">Biaya Lainnya</label>
                                    <input type="number" name="other_fees[other_fee]" class="text-field-input" step="0.01" placeholder="0">
                                </div>
                            </div>
                        </div>
                    </div>

                    <button type="submit" class="dark-brown-button">
                         Simpan Tarif Baru
                    </button>
                </div>
            </form>
        </div>
    </div>
    
    <div class="popup" id="delete-tariff">
        <div class="popup-overlay"></div>

        <div class="popup-card popup-md">
            <div class="popup-close-wrapper">
                <button class="popup-close">
                    <i class="fa-solid fa-xmark"></i>
                </button>
            </div>

            <div class="popup-header">Hapus Tarif Ini</div>

            <div class="popup-body btn-delete-wrapper">
                <button id="confirm-delete-btn" class="light-brown-btn">Ya</button>
                <button class="dark-brown-button" data-close="delete-tariff">Tidak</button>
            </div>
        </div>
    </div>
</div>
@endsection