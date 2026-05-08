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

    @if(session('success'))
        <div class="mb-4 p-4 bg-emerald-500 text-white rounded-xl font-bold shadow-lg">
            {{ session('success') }}
        </div>
    @endif

    @if ($errors->any())
        <div class="mb-4 p-4 bg-rose-100 border border-rose-300 text-rose-700 rounded-xl">
            <p class="font-bold mb-2">Validation Error</p>

            <ul class="list-disc pl-5 text-sm">
                @foreach ($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <div class="flex flex-col gap-6">

        <div class="toolbar mb-2">
            <div class="search-wrapper">
                <input type="text" placeholder="Search Tenant..">
                <span><i class="fa-solid fa-magnifying-glass"></i></span>
            </div>

            <div class="toolbar-action">
                <button class="light-brown-btn btn-small" data-popup="add-invoices">
                    <span><i class="fa-solid fa-plus"></i></span>
                    <span>Generate Invoice</span>
                </button>
            </div>
        </div>

        <div class="table-wrapper">
            @foreach($invoices->groupBy('tenant.tenant_name') as $tenantName => $groupedInvoices)
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

                                                <button
                                                    type="button"
                                                    class="dark-brown-btn-action"
                                                    data-popup="delete-invoice"
                                                    data-id="{{ $invoice->id }}"
                                                >
                                                    <span><i class="fa-solid fa-trash"></i></span>
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
            @endforeach
        </div>

    </div>

    <div class="mt-6">
        {{ $invoices->links() }}
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
                                <i class="fa-solid fa-file-invoice-dollar mr-2"></i> Generate & Save
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

            <div class="popup-header">Hapus Invoice Ini?</div>

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