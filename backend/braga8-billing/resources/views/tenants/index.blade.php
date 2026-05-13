@extends('layouts.app')

@section('content')
<div class="min-h-screen">
    <div class="mb-10 flex flex-col md:flex-row md:items-end justify-between gap-4 border-zinc-200 pb-8">
        <div>
            <h1 class="title-text">Tenant List</h1>
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
                    'tenant-created' => [
                        'title' => 'Tenant Added!',
                        'desc' => 'Data tenant berhasil ditambahkan.',
                        'icon' => 'fa-circle-check'
                    ],

                    'tenant-updated' => [
                        'title' => 'Tenant Updated!',
                        'desc' => 'Perubahan berhasil disimpan.',
                        'icon' => 'fa-pen'
                    ],

                    'tenant-deleted' => [
                        'title' => 'Tenant Deleted!',
                        'desc' => 'Data tenant berhasil dihapus.',
                        'icon' => 'fa-trash-can'
                    ],
                ];

                $statusKey = session('status');
                $current = $alerts[$statusKey] ?? null;
            @endphp

            @if ($current)
                <div
                    id="universal-alert" class="fixed top-6 right-6 z-[9999] flex items-center justify-between p-5 min-w-[380px] text-white border border-white/20 rounded-2xl backdrop-blur-md shadow-[0_10px_40px_rgba(0,0,0,0.5)] transition-all duration-500" style="background-color: rgba(96, 35, 22, 0.6);">
                    <div class="flex items-center gap-4">
                        <div
                            class="flex items-center justify-center w-12 h-12 rounded-2xl bg-[#FA8327]/10 border border-[#FA8327]/20">
                            <i class="fa-solid {{ $current['icon'] }} text-[#FA8327] text-lg"></i>
                        </div>

                        <div class="flex flex-col">
                            <p class="text-sm font-bold tracking-wide">
                                {{ $current['title'] }}
                            </p>
                            <p class="text-xs text-white/55 font-light">
                                {{ $current['desc'] }}
                            </p>
                        </div>
                    </div>
                    <button type="button" onclick="closeUniversalAlert()" class="w-9 h-9 rounded-xl flex items-center justify-center text-white/30 hover:text-[#FA8327] hover:bg-white/5 transition-all" >
                        <i class="fa-solid fa-xmark"></i>
                    </button>
                </div>

                <script>
                    function closeUniversalAlert() {
                        const alert = document.getElementById('universal-alert');

                        if (alert) {
                            alert.style.opacity = '0';
                            alert.style.transform = 'translateX(40px) scale(.96)';

                            setTimeout(() => {
                                alert.remove();
                            }, 500);
                        }
                    }

                    setTimeout(closeUniversalAlert, 4500);
                </script>
            @endif
        @endif
        
        <div class="toolbar">
            <form action="{{ route('tenants.index') }}" method="GET" class="search-wrapper">
                <input type="text" name="search" value="{{ request('search') }}" placeholder="Search Tenant / PIC...">
                <span><i class="fa-solid fa-magnifying-glass"></i></span>
            </form>
            <div class="toolbar-action">
                <button class="light-brown-btn btn-small" data-popup="addTenantModal">
                    <span><i class="fa-solid fa-plus"></i></span>
                    <span>Add Tenant</span>
                </button>
            </div>
        </div>

        <div class="table-wrapper">
            <div class="table-card mb-8">
                <div class="table-card-header">
                    <div class="table-card-title">
                        <span class="label">Total Tenants:</span>
                        <span class="value">{{ $tenants->total() }}</span>
                    </div>
                </div>
                <table class="table">
                    <thead>
                        <tr>
                            <th class="w-[30%]">Tenant Name</th>
                            <th class="w-[30%]">Company</th>
                            <th class="w-[20%]">PIC</th>
                            <th class="text-center w-[20%]">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($tenants as $tenant)
                            <tr>
                                <td>{{ $tenant->tenant_name }}</td>
                                <td class="text-zinc-500">{{ $tenant->company_name ?? '-' }}</td>
                                <td>{{ $tenant->person_in_charge }}</td>
                                <td class="actions">
                                    <div class="flex gap-2 justify-center">
                                        <button type="button" class="light-green-btn-action px-4 py-2" data-popup="detail-tenant-{{ $tenant->id }}">
                                            <i class="fa-solid fa-eye mr-1"></i> Detail
                                        </button>
                                        <button type="button" class="light-brown-btn-action px-4 py-2" data-popup="edit-tenant-{{ $tenant->id }}">
                                            <i class="fa-solid fa-pen"></i> Edit
                                        </button>
                                        <form id="delete-form-{{ $tenant->id }}" action="{{ route('tenants.destroy', $tenant->id) }}" method="POST" class="m-0 p-0">
                                            @csrf
                                            @method('DELETE')
                                            <button type="button" 
                                                    class="dark-brown-btn-action px-4 py-2" 
                                                    data-popup="delete-tenant-modal" 
                                                    data-id="{{ $tenant->id }}">
                                                <i class="fa-solid fa-trash"></i> Hapus
                                            </button>
                                        </form>
                                    </div>
                                </td>
                            </tr>

                            <div class="popup" id="detail-tenant-{{ $tenant->id }}">
                                <div class="popup-overlay"></div>
                                <div class="popup-card popup-md"> {{-- Sesuai class CSS kamu --}}
                                    <div class="popup-close-wrapper">
                                        <button class="popup-close" data-close="detail-tenant-{{ $tenant->id }}">
                                            <i class="fa-solid fa-xmark"></i>
                                        </button>
                                    </div>

                                    <div class="popup-header">Detail Tenant</div>

                                    <div class="popup-body">
                                        <div class="flex flex-col gap-6">
                                            
                                            <div class="flex items-center gap-5 p-4 rounded-2xl bg-[#ffffff05] border border-white/10">
                                                <div class="profile-container" style="width: 60px; height: 60px;">
                                                    <div class="profile-icon">
                                                        <span class="text-[#a04d30] font-black text-2xl">{{ substr($tenant->tenant_name, 0, 1) }}</span>
                                                    </div>
                                                </div>
                                                <div class="user-info">
                                                    <p>{{ $tenant->tenant_name }}</p>
                                                    <p class="subtitle-text" style="opacity: 1; color: #FA8327;">{{ $tenant->business_type ?? 'Tenant' }}</p>
                                                </div>
                                            </div>

                                            <div class="grid grid-cols-1 gap-5">
                                                <div>
                                                    <div class="grid grid-cols-2 gap-y-6 text-left">
                                                        <div class="detail-item">
                                                            <p>Person In Charge</p>
                                                            <p>{{ $tenant->person_in_charge }}</p>
                                                        </div>
                                                        <div class="detail-item">
                                                            <p>Legal Entity</p>
                                                            <p>{{ $tenant->company_name ?? '-' }}</p>
                                                        </div>
                                                        <div class="detail-item">
                                                            <p>Phone Number</p>
                                                            <p>{{ $tenant->contact_phone }}</p>
                                                        </div>
                                                        <div class="detail-item">
                                                            <p>Email Address</p>
                                                            <p>{{ $tenant->contact_email }}</p>
                                                        </div>
                                                        <div class="detail-item">
                                                            <p>ID</p>
                                                            <p>#BRG-{{ $tenant->id }}</p>
                                                        </div>
                                                        <div class="detail-item">
                                                            <p>Registrasi</p>
                                                            <p>{{ $tenant->created_at->format('d M Y') }}</p>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div class="popup" id="edit-tenant-{{ $tenant->id }}">
                                <div class="popup-overlay"></div>
                                <div class="popup-card popup-md text-left">
                                    <div class="popup-close-wrapper">
                                        <button class="popup-close" data-close="edit-tenant-{{ $tenant->id }}">
                                            <i class="fa-solid fa-xmark"></i>
                                        </button>
                                    </div>

                                    <div class="popup-header">Edit Data Tenant</div>

                                    <form action="{{ route('tenants.update', $tenant->id) }}" method="POST">
                                        @csrf
                                        @method('PUT')
                                        <div class="popup-body">
                                            <div class="flex flex-col gap-5">
                                                <div>

                                                    <div class="text-field">
                                                        <label class="text-field-label">Tenant Name <span class="text-[#FA8327]">*</span></label>
                                                        <input type="text" name="tenant_name" value="{{ $tenant->tenant_name }}" class="text-field-input" required>
                                                    </div>

                                                    <div class="grid grid-cols-2 gap-4">
                                                        <div class="text-field">
                                                            <label class="text-field-label">PIC <span class="text-[#FA8327]">*</span></label>
                                                            <input type="text" name="person_in_charge" value="{{ $tenant->person_in_charge }}" class="text-field-input" required>
                                                        </div>
                                                        <div class="text-field">
                                                            <label class="text-field-label">Business Type</label>
                                                            <input type="text" name="business_type" value="{{ $tenant->business_type }}" class="text-field-input">
                                                        </div>
                                                    </div>

                                                    <div class="text-field">
                                                        <label class="text-field-label">Phone Number</label>
                                                        <input type="text" name="contact_phone" value="{{ $tenant->contact_phone }}" class="text-field-input">
                                                    </div>

                                                    <div class="text-field">
                                                        <label class="text-field-label">Email Address</label>
                                                        <input type="email" name="contact_email" value="{{ $tenant->contact_email }}" class="text-field-input">
                                                    </div>

                                                    <div class="text-field">
                                                        <label class="text-field-label">Company Name</label>
                                                        <input type="text" name="company_name" value="{{ $tenant->company_name }}" class="text-field-input">
                                                    </div>
                                                </div>

                                                <button type="submit" class="light-brown-btn">
                                                    Update Tenant
                                                </button>
                                            </div>
                                        </div>
                                    </form>
                                </div>
                            </div>
                        @empty
                            <tr>
                                <td colspan="4" class="p-10 text-center text-zinc-400 italic">Data tenant tidak ditemukan</td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>

        <div class="flex flex-col md:flex-row justify-between items-center gap-4 mt-6 px-2">
            <div class="text-sm text-zinc-500">
                Showing <span class="text-white">{{ $tenants->firstItem() }}</span> to <span class="text-white">{{ $tenants->lastItem() }}</span> of <span class="text-white">{{ $tenants->total() }}</span> results
            </div>
            <div class="braga-pagination">
                {{ $tenants->links() }}
            </div>
        </div>
    </div>
</div>

<div class="popup" id="addTenantModal">
    <div class="popup-overlay"></div>
    <div class="popup-card popup-md text-left"> {{-- Pakai popup-lg biar grid-nya enak dilihat --}}
        <div class="popup-close-wrapper">
            <button class="popup-close" data-close="addTenantModal">
                <i class="fa-solid fa-xmark"></i>
            </button>
        </div>

        <div class="popup-header">Registrasi Tenant Baru</div>
        
        <form action="{{ route('tenants.store') }}" method="POST">
            @csrf
            <div class="popup-body">
                <div class="flex flex-col gap-6">
                    
                    <div>
                        <div class="text-field">
                            <label class="text-field-label">Tenant Name <span class="text-[#FA8327]">*</span></label>
                            <input type="text" name="tenant_name" value="{{ old('tenant_name') }}" class="text-field-input" placeholder="Nama Brand/Toko" required>
                            @error('tenant_name') <p class="text-[10px] text-[#FA8327] mt-1 italic">{{ $message }}</p> @enderror
                        </div>
                        <div class="text-field">
                            <label class="text-field-label">Company Name</label>
                            <input type="text" name="company_name" value="{{ old('company_name') }}" class="text-field-input" placeholder="PT / CV (Optional)">
                            @error('company_name') <p class="text-[10px] text-[#FA8327] mt-1 italic">{{ $message }}</p> @enderror
                        </div>

                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div class="text-field">
                                <label class="text-field-label">Person In Charge (PIC) <span class="text-[#FA8327]">*</span></label>
                                <input type="text" name="person_in_charge" value="{{ old('person_in_charge') }}" class="text-field-input" placeholder="Nama PIC" required>
                                @error('person_in_charge') <p class="text-[10px] text-[#FA8327] mt-1 italic">{{ $message }}</p> @enderror
                            </div>

                            <div class="text-field">
                                <label class="text-field-label">Business Type</label>
                                <input type="text" name="business_type" value="{{ old('business_type') }}" class="text-field-input" placeholder="e.g. Café, Retail">
                                @error('business_type') <p class="text-[10px] text-[#FA8327] mt-1 italic">{{ $message }}</p> @enderror
                            </div>
                        </div>

                        <div class="text-field">
                            <label class="text-field-label">Phone Number</label>
                            <input type="text" name="contact_phone" value="{{ old('contact_phone') }}" class="text-field-input" placeholder="08xxxxxx">
                            @error('contact_phone') <p class="text-[10px] text-[#FA8327] mt-1 italic">{{ $message }}</p> @enderror
                        </div>
                        <div class="text-field">
                            <label class="text-field-label">Email Address</label>
                            <input type="email" name="contact_email" value="{{ old('contact_email') }}" class="text-field-input" placeholder="mail@example.com">
                            @error('contact_email') <p class="text-[10px] text-[#FA8327] mt-1 italic">{{ $message }}</p> @enderror
                        </div>
                    </div>

                    <button type="submit" class="light-brown-btn py-4">
                        Simpan Data Tenant
                    </button>

                </div>
            </div>
        </form>
    </div>
</div>

<div class="popup" id="delete-tenant-modal">
    <div class="popup-overlay"></div>
    <div class="popup-card popup-md">
        <div class="popup-close-wrapper">
            <button class="popup-close" data-close="delete-tenant-modal">
                <i class="fa-solid fa-xmark"></i>
            </button>
        </div>
        <div class="popup-header">Hapus Data Tenant</div>
        <div class="popup-body">
            <div class="btn-delete-wrapper">
                <button type="button" id="confirm-delete-btn" class="light-brown-btn">Ya</button>
                <button type="button" class="dark-brown-button" data-close="delete-tenant-modal">Tidak</button>
            </div>
        </div>
    </div>
</div>
@endsection