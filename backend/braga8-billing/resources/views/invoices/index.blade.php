@extends('layouts.app')

@section('content')
<div class="min-h-screen">

    <div class="mb-10 flex flex-col md:flex-row md:items-end justify-between gap-4 pb-8">

        <div>
            <h1 class="title-text">Tagihan</h1>
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

    @if (session('success'))
        <div id="universal-success-alert" class="fixed top-6 right-6 z-[9999] flex items-center justify-between p-5 min-w-[380px] text-white border border-white/20 rounded-2xl backdrop-blur-md shadow-[0_10px_40px_rgba(0,0,0,0.5)] transition-all duration-500" style="background-color: rgba(6, 78, 59, 0.6);">
            <div class="flex items-center gap-4">
                <div class="flex items-center justify-center w-11 h-11 rounded-xl bg-white/10 border border-white/10 shadow-inner">
                    <i class="fa-solid fa-circle-check text-emerald-400 text-lg"></i>
                </div>
                <div class="flex flex-col gap-0.5">
                    <p class="text-sm font-bold tracking-wide">Berhasil!</p>
                    <p class="text-xs text-white/50 font-light">{{ session('success') }}</p>
                </div>
            </div>
            <button type="button" onclick="closeSuccessAlert()" class="p-2 text-white/20 hover:text-emerald-400 transition-colors">
                <i class="fa-solid fa-xmark text-lg"></i>
            </button>
        </div>
        <script>
            function closeSuccessAlert() {
                const alert = document.getElementById('universal-success-alert');
                if (alert) {
                    alert.style.opacity = '0';
                    alert.style.transform = 'translateX(30px)';
                    setTimeout(() => alert.remove(), 500);
                }
            }
            setTimeout(closeSuccessAlert, 4500);
        </script>
    @endif

    @if ($errors->any())
        <div id="error-alert" class="fixed top-6 right-6 z-[9999] flex items-start justify-between p-5 min-w-[380px] text-white border border-white/10 rounded-2xl backdrop-blur-md shadow-[0_10px_40px_rgba(0,0,0,0.5)] transition-all duration-500" 
            style="background-color: rgba(60, 0, 0, 0.75); border: 1px solid rgba(255, 255, 255, 0.1);">
            <div class="flex items-start gap-4">
                <div class="flex items-center justify-center w-11 h-11 rounded-xl bg-red-950/40 border border-white/5 shadow-inner shrink-0">
                    <i class="fa-solid fa-circle-exclamation text-red-500 text-lg"></i>
                </div>
                <div class="flex flex-col gap-1">
                    <p class="text-sm font-bold tracking-wide text-red-100">Terjadi Kesalahan!</p>
                    <ul class="list-none p-0 m-0">
                        @foreach ($errors->all() as $error)
                            <li class="text-xs text-white/70 font-light">{{ $error }}</li>
                        @endforeach
                    </ul>
                </div>
            </div>
            <button type="button" onclick="closeErrorAlert()" class="p-2 text-white/20 hover:text-red-400 transition-colors">
                <i class="fa-solid fa-xmark text-lg"></i>
            </button>
        </div>

        <script>
            function closeErrorAlert() {
                const alert = document.getElementById('error-alert');
                if (alert) {
                    alert.style.opacity = '0';
                    alert.style.transform = 'translateX(30px)';
                    setTimeout(() => alert.remove(), 500);
                }
            }
            setTimeout(closeErrorAlert, 4500);
        </script>
    @endif

    <div class="flex flex-col gap-6">

        <div class="toolbar mb-2">
            <div class="search-wrapper">
                <input type="text" placeholder="Cari Tagihan..">
                <span><i class="fa-solid fa-magnifying-glass"></i></span>
            </div>

            <div class="toolbar-action">
                <button class="light-brown-btn btn-small" data-popup="add-invoices">
                    <span><i class="fa-solid fa-plus"></i></span>
                    <span>Buat Tagihan</span>
                </button>
            </div>
        </div>

        <div class="table-wrapper">
            @forelse($invoices->groupBy('tenant.tenant_name') as $tenantName => $groupedInvoices)
                <div class="table-card mb-4">
                    <div class="table-card-header">
                        <div class="table-card-title">
                            <span class="label">Tenant:</span>
                            <span class="value">{{ $tenantName }}</span>
                        </div>
                        <div class="table-card-meta">
                            {{ $groupedInvoices->count() }} Invoice(s)
                        </div>
                    </div>
                    <table class="table">
                        <thead>
                            <tr>
                                <th>Invoice No</th>
                                <th>Unit</th>
                                <th>Total</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($groupedInvoices as $invoice)
                                <tr>
                                    <td>{{ $invoice->invoice_number }}</td>
                                    <td>{{ $invoice->unit->unit_number }}</td>
                                    <td>Rp {{ number_format($invoice->total_amount, 0, ',', '.') }}</td>
                                    <td class="status">
                                        @if($invoice->notified_at)
                                            <button class="dark-green-btn">Sended</button>
                                        @else
                                            <button class="red-btn">Not Sended</button>
                                        @endif
                                    </td>
                                    <td class="actions">
                                        <div class="grid grid-cols-2 lg:grid-cols-4 gap-2 w-full">    
                                            <a href="{{ route('invoices.notify', $invoice->id) }}" 
                                            target="_blank" 
                                            onclick="setTimeout(() => { window.location.reload(); }, 1000);"
                                            class="light-grey-btn-action">
                                                <span><i class="fa-brands fa-whatsapp"></i></span>
                                                <span>Send</span>
                                            </a>

                                            <a href="{{ route('invoices.show', $invoice) }}" class="light-green-btn-action">
                                                <span><i class="fa-solid fa-eye"></i></span>
                                                <span>View</span>
                                            </a>

                                            <a href="{{ route('invoices.pdf', $invoice) }}" class="light-brown-btn-action">
                                                <span><i class="fa-solid fa-file-pdf"></i></span>
                                                <span>Export PDF</span>
                                            </a>

                                            <form 
                                                id="delete-form-{{ $invoice->id }}"
                                                action="{{ route('invoices.destroy', $invoice) }}"
                                                method="POST"
                                                class="inline"
                                            >
                                                @csrf
                                                @method('DELETE')

                                                <button type="button" class="dark-brown-btn-action" 
                                                    data-popup="delete-invoice" 
                                                    data-id="{{ $invoice->id }}" 
                                                    data-invoice="{{ $invoice->invoice_number }}"> <span><i class="fa-solid fa-trash"></i></span> 
                                                    <span>Hapus</span>
                                                </button>
                                            </form>
                                        </div>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            @empty
            <div class="table-card p-10 text-center text-zinc-400 italic">
                Data tagihan tidak ditemukan
            </div>
            @endforelse
        </div>

        <div class="flex flex-col md:flex-row justify-between items-center gap-4 px-2">
            <div class="text-sm text-zinc-500">
                Showing <span class="text-white">{{ $invoices->firstItem() }}</span> 
                to <span class="text-white">{{ $invoices->lastItem() }}</span> 
                of <span class="text-white">{{ $invoices->total() }}</span> results
            </div>

            <div class="braga-pagination">
                {{ $invoices->links('pagination::bootstrap-4') }}
            </div>
        </div>

    </div>

    <div class="popup" id="add-invoices">
        <div class="popup-overlay"></div>

        <div class="popup-card popup-md">
            <div class="popup-close-wrapper">
                <button class="popup-close" data-close="add-invoices">
                    <i class="fa-solid fa-xmark"></i>
                </button>
            </div>
            <div class="popup-header">Generate Invoices</div>
            
            <div class="popup-body">
                <form action="{{ route('invoices.store') }}" method="POST" id="invoiceForm">
                    @csrf
                    
                    
                    <div class="flex flex-col gap-4">
                        
                        <div class="text-field">
                            <label class="text-field-label">Select Tenant</label>
                            <div class="custom-dropdown" id="tenantDropdown">
                                <div class="dropdown-selected">
                                    <span class="placeholder">-- Pilih Tenant --</span>
                                    <i class="fa-solid fa-angle-down"></i>
                                </div>
                                <div class="dropdown-options">
                                    @foreach($tenants as $tenant)
                                        <div class="option" data-value="{{ $tenant->id }}">
                                            {{ $tenant->tenant_name }}
                                        </div>
                                    @endforeach
                                </div>
                                <input type="hidden" name="tenant_id" id="tenant_id_input" required>
                            </div>
                        </div>

                        <div class="text-field">
                            <label class="text-field-label">Select Unit</label>
                            <div class="custom-dropdown" id="unitDropdown">
                                <div class="dropdown-selected">
                                    <span class="placeholder">-- Pilih Unit --</span>
                                    <i class="fa-solid fa-angle-down"></i>
                                </div>
                                <div class="dropdown-options" id="unitOptionsContainer">
                                    @foreach($units as $unit)
                                        <div class="option" 
                                            data-value="{{ $unit->id }}" 
                                            data-tenant="{{ $unit->tenant_id }}">
                                            {{ $unit->unit_number }} (Floor {{ $unit->floor }})
                                        </div>
                                    @endforeach
                                </div>
                                <input type="hidden" name="unit_id" id="unit_id_input" required>
                            </div>
                            <p class="text-[10px] text-zinc-400 mt-1 italic">Pastikan meteran sudah di-input untuk unit ini.</p>
                        </div>

                        <div class="grid grid-cols-2 gap-4 mt-2">
                            <div class="text-field">
                                <label class="text-field-label">Billing Period</label>
                                <input type="text" class="text-field-input bg-zinc-100 opacity-70" 
                                    value="{{ now()->translatedFormat('F Y') }}" readonly>
                            </div>
                            <div class="text-field">
                                <label class="text-field-label text-blue-600">Manual Fee (Opsional)</label>
                                <input type="number" name="manual_other_fee" class="text-field-input" 
                                    placeholder="Rp 0" min="0">
                            </div>
                        </div>

                        <div class="mt-4 flex gap-2">
                            <button type="submit" class="dark-brown-button flex-1 py-3">
                                Generate & Save
                            </button>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>
    
    <div class="popup" id="delete-invoice">
        <div class="popup-overlay"></div>

        <div class="popup-card popup-md">
            <div class="popup-close-wrapper">
                <button class="popup-close">
                    <i class="fa-solid fa-xmark"></i>
                </button>
            </div>

            <div class="popup-header">Hapus Invoice <span id="display-invoice-number" class="text-[#FA8327]"></span>?</div>
            <div class="popup-body btn-delete-wrapper">
                <button id="confirm-delete-btn" class="light-brown-btn">
                    Ya
                </button>

                <button 
                    class="dark-brown-button"
                    data-close="delete-invoice"
                >
                    Tidak
                </button>
            </div>
        </div>
    </div>
</div>

@endsection