@extends('layouts.app') 

@section('content') 
@if (session('status')) 
    @php 
    $alerts = [ 
        'payment-stored' => ['title' => 'Pembayaran Ditambahkan!', 'desc' => 'Data pembayaran baru berhasil disimpan.', 'icon' => 'fa-circle-check'], 
        'payment-updated' => ['title' => 'Pembayaran Diperbarui!', 'desc' => 'Perubahan pembayaran berhasil disimpan.', 'icon' => 'fa-pen-to-square'], 
        'payment-deleted' => ['title' => 'Pembayaran Dihapus!', 'desc' => 'Riwayat pembayaran berhasil dihapus.', 'icon' => 'fa-trash-can'], 
        'profile-updated' => ['title' => 'Profil Diperbarui!', 'desc' => 'Informasi akun berhasil diperbarui.', 'icon' => 'fa-user-check'], 
        'remind-cooldown' => ['title' => 'Tunggu Sebentar!', 'desc' => 'Pengingat sudah dikirim sebelumnya.', 'icon' => 'fa-clock'], 
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

<div class="min-h-screen"> 
    <div class="mb-10 flex flex-col md:flex-row md:items-end justify-between gap-4 pb-8"> 
        <div> 
            <h1 class="title-text">Riwayat Pembayaran</h1> 
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
        <div class="toolbar"> 
            <div class="search-wrapper"> 
                <input type="text" placeholder="Cari Pembayaran.."> 
                <span><i class="fa-solid fa-magnifying-glass"></i></span> 
            </div> 
            <div class="toolbar-action"> 
                <button type="button" class="light-brown-btn btn-small" data-popup="add-payment-modal"> 
                    <i class="fa-solid fa-plus"></i> <span>Tambah Pembayaran</span> 
                </button> 
            </div> 
        </div> 

        <div class="card-image-container mb-2"> 
            <div class="card card-with-image"> 
                <div class="card-image"></div> 
                <div class="card-body"> 
                    <p class="card-label">Total Tagihan</p> 
                    <p class="card-value">Rp {{ number_format($totalBill, 0, ',', '.') }}</p> 
                </div> 
            </div> 
            <div class="card card-with-image"> 
                <div class="card-image"></div> 
                <div class="card-body"> 
                    <p class="card-label">Total Pembayaran Diterima</p> 
                    <p class="card-value">Rp {{ number_format($totalCollected, 0, ',', '.') }}</p> 
                </div> 
            </div> 
            <div class="card card-with-image"> 
                <div class="card-image"></div> 
                <div class="card-body"> 
                    <p class="card-label">Tagihan Tertunggak</p> 
                    <p class="card-value">Rp {{ number_format($outstandingBill, 0, ',', '.') }}</p> 
                </div> 
            </div> 
        </div> 

        <div class="table-wrapper"> 
            @forelse($payments->groupBy('invoice.tenant.tenant_name') as $tenantName => $tenantPayments) 
            <div class="table-card mb-4"> 
                <div class="table-card-header"> 
                    <div class="table-card-title"> 
                        <span class="label">Penyewa:</span> 
                        <span class="value">{{ $tenantName }}</span> 
                    </div> 
                    <div class="table-card-meta"> {{ $tenantPayments->count() }} Riwayat </div> 
                </div> 
                <div class="table-responsive"> 
                    <table class="table"> 
                        <thead> 
                            <tr> 
                                <th>No. Invoice</th> 
                                <th>Unit</th> 
                                <th>Total</th> 
                                <th>Status</th> 
                                <th class="text-center">Aksi</th> 
                            </tr> 
                        </thead> 
                        <tbody> 
                            @foreach($tenantPayments as $payment) 
                            <tr> 
                                <td>{{ $payment->invoice->invoice_number }}</td> 
                                <td>{{ $payment->invoice->unit->unit_number ?? '-' }}</td> 
                                <td>Rp {{ number_format($payment->amount_paid, 0, ',', '.') }}</td> 
                                <td class="status"> 
                                    <button class="{{ $payment->status == 'verified' ? 'dark-green-btn' : ($payment->status == 'rejected' ? 'red-btn' : 'light-brown-btn-action') }} pointer-events-none"> 
                                        {{ strtoupper($payment->status) }} 
                                    </button> 
                                </td> 
                                <td class="actions"> 
                                    <div class="flex items-center justify-center gap-2"> 
                                        @if($payment->status !== 'verified') 
                                            @php $isCooldown = $payment->reminded_at && $payment->reminded_at->diffInDays(now()) < 2; @endphp 
                                            @if($isCooldown) 
                                                <div class="light-grey-btn-action opacity-50 cursor-not-allowed flex items-center py-1"> 
                                                    <i class="fa-solid fa-clock-rotate-left text-zinc-400"></i> 
                                                    <span class="text-[9px] font-bold">Wait {{ ceil(2 - $payment->reminded_at->diffInDays(now())) }}d</span> 
                                                </div> 
                                            @else 
                                                <form action="{{ route('payments.remind', $payment->id) }}" method="POST" class="m-0 p-0" target="_blank"> 
                                                    @csrf 
                                                    <button type="submit" class="light-grey-btn-action group" onclick="setTimeout(() => { window.location.reload(); }, 2000);"> 
                                                        <span><i class="fa-brands fa-whatsapp scale-120"></i></span> <span class="text-xs">Ingatkan</span> 
                                                    </button> 
                                                </form> 
                                            @endif 
                                        @endif 
                                        
                                        @if($payment->proof_img) 
                                        <button class="light-green-btn-action" data-popup="detail-payment-{{ $payment->id }}"> 
                                            <span><i class="fa-solid fa-eye"></i></span> <span class="text-xs">Bukti Bayar</span> 
                                        </button> 
                                        @endif 
                                        
                                        <button class="light-brown-btn-action" data-popup="edit-payment-{{ $payment->id }}"> 
                                            <span><i class="fa-solid fa-pen"></i></span> <span class="text-xs">Ubah</span> 
                                        </button> 

                                        <form id="delete-form-{{ $payment->id }}" action="{{ route('payments.destroy', $payment->id) }}" method="POST" class="m-0 p-0"> 
                                            @csrf @method('DELETE') 
                                            <button type="button" class="dark-brown-btn-action" data-popup="delete-tariff" data-id="{{ $payment->id }}"> 
                                                <span><i class="fa-solid fa-trash"></i></span> <span class="text-xs">Hapus</span> 
                                            </button> 
                                        </form> 
                                    </div> 
                                </td> 
                            </tr> 
                            @endforeach 
                        </tbody> 
                    </table> 
                </div> 
            </div> 
            @empty
            <div class="table-card p-10 text-center text-zinc-400 italic">
                Belum ada log pembayaran.
            </div>
        @endforelse

        <div class="mt-6 pagination-wrapper">
            {{ $payments->links() }}
        </div>
    </div>

    @foreach($payments as $payment)
    <div class="popup" id="edit-payment-{{ $payment->id }}"> 
        <div class="popup-overlay"></div> 
        <div class="popup-card popup-md" style="overflow: visible !important;"> 
            <div class="popup-close-wrapper"> 
                <button class="popup-close" data-close="edit-payment-{{ $payment->id }}"> 
                    <i class="fa-solid fa-xmark"></i> 
                </button> 
            </div> 
            <div class="popup-header">Edit Pembayaran</div> 
            <div class="popup-body"> 
                <form action="{{ route('payments.update', $payment->id) }}" method="POST" enctype="multipart/form-data"> 
                    @csrf @method('PUT') 
                    <div class="flex flex-col gap-6"> 
                        <div> 
                            <div class="text-field"> 
                                <label class="text-field-label text-left">Referensi Invoice</label> 
                                <div class="text-field-input opacity-70 bg-zinc-200/50 flex items-center justify-between"> 
                                    <span class="text-zinc-600 font-medium">{{ $payment->invoice->invoice_number }} - {{ $payment->invoice->tenant->tenant_name }}</span> 
                                    <i class="fa-solid fa-lock text-[10px] text-zinc-400"></i> 
                                </div> 
                                <input type="hidden" name="invoice_id" value="{{ $payment->invoice_id }}"> 
                            </div> 
                            <div class="grid grid-cols-2 gap-4"> 
                                <div class="text-field"> 
                                    <label class="text-field-label text-left">Jumlah Bayar</label> 
                                    <input type="number" name="amount_paid" value="{{ old('amount_paid', $payment->amount_paid) }}" class="text-field-input" required step="any"> 
                                    <p class="text-[9px] text-zinc-500 mt-1 italic text-left">Tagihan: Rp {{ number_format($payment->invoice->total_amount, 0, ',', '.') }}</p> 
                                </div> 
                                <div class="text-field"> 
                                    <label class="text-field-label text-left">Tanggal Bayar</label> 
                                    <input type="date" name="payment_date" value="{{ old('payment_date', $payment->payment_date->format('Y-m-d')) }}" class="text-field-input" required> 
                                </div> 
                            </div> 
                            <div class="grid grid-cols-2 gap-4"> 
                                <div class="text-field"> 
                                    <label class="text-field-label text-left">Metode Pembayaran</label> 
                                    <div class="custom-dropdown"> 
                                        <div class="dropdown-selected"> 
                                            <span class="placeholder">{{ $payment->paid_using }}</span> 
                                            <i class="fa-solid fa-chevron-down text-[10px] text-zinc-500"></i> 
                                        </div> 
                                        <div class="dropdown-options"> 
                                            <div class="option">Bank Transfer</div> 
                                            <div class="option">Cash</div> 
                                            <div class="option">E-Wallet</div> 
                                        </div> 
                                        <input type="hidden" name="paid_using" value="{{ $payment->paid_using }}"> 
                                    </div> 
                                </div> 
                                <div class="text-field"> 
                                    <label class="text-field-label text-left">Status</label> 
                                    <div class="custom-dropdown"> 
                                        <div class="dropdown-selected"> 
                                            <span class="placeholder">{{ strtoupper($payment->status) }}</span> 
                                            <i class="fa-solid fa-chevron-down text-[10px] text-zinc-500"></i> 
                                        </div> 
                                        <div class="dropdown-options"> 
                                            <div class="option" data-value="pending">Pending</div> 
                                            <div class="option" data-value="rejected">Rejected</div> 
                                            <div class="option" data-value="verified">Verified</div> 
                                        </div> 
                                        <input type="hidden" name="status" value="{{ $payment->status }}"> 
                                    </div> 
                                </div> 
                            </div> 
                            <div class="text-field"> 
                                <label class="text-field-label text-left">Bukti Bayar (Ganti jika perlu)</label> 
                                @if($payment->proof_img) 
                                <div class="mb-2 flex items-center gap-3"> 
                                    <img src="{{ asset('storage/' . $payment->proof_img) }}" class="w-18 h-18 object-cover rounded-lg border border-zinc-400"> 
                                    <span class="text-[10px] text-zinc-500 italic">Gambar saat ini</span> 
                                </div> 
                                @endif 
                                <input type="file" name="proof_img" class="text-xs file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-xs file:font-semibold file:bg-zinc-100 file:text-zinc-700 hover:file:bg-zinc-200 cursor-pointer w-full text-zinc-400"> 
                            </div> 
                        </div> 
                        <div class="flex gap-3 mt-2"> 
                            <button type="button" class="light-grey-btn flex-1 py-3" data-close="edit-payment-{{ $payment->id }}">Batal</button> 
                            <button type="submit" class="dark-brown-button flex-[2] py-3"> <i class="fa-solid fa-rotate mr-2"></i> Perbarui </button> 
                        </div> 
                    </div> 
                </form> 
            </div> 
        </div> 
    </div> 

    @if($payment->proof_img) 
    <div class="popup" id="detail-payment-{{ $payment->id }}"> 
        <div class="popup-overlay"></div> 
        <div class="popup-card popup-md"> 
            <div class="popup-close-wrapper"> <button class="popup-close" data-close="detail-payment-{{ $payment->id }}"><i class="fa-solid fa-xmark"></i></button> </div> 
            <div class="popup-header">Evidence: {{ $payment->invoice->invoice_number }}</div> 
            <div class="popup-body text-center"> <img src="{{ asset('storage/' . $payment->proof_img) }}" class="w-full rounded-lg shadow-lg"> </div> 
        </div> 
    </div> 
    @endif
    @endforeach

    <div class="popup" id="add-payment-modal"> 
        <div class="popup-overlay"></div> 
        <div class="popup-card popup-md" style="overflow: visible !important;"> 
            <div class="popup-close-wrapper"> <button class="popup-close" data-close="add-payment-modal"> <i class="fa-solid fa-xmark"></i> </button> </div> 
            <div class="popup-header">Tambah Pembayaran Baru</div> 
            <div class="popup-body"> 
                <form action="{{ route('payments.store') }}" method="POST" enctype="multipart/form-data"> 
                    @csrf 
                    <div class="flex flex-col gap-6"> 
                        <div>
                            <div class="text-field"> 
                                <label class="text-field-label text-left">Pilih Invoice</label> 
                                <div class="custom-dropdown"> 
                                    <div class="dropdown-selected"> 
                                        <span class="placeholder">-- Pilih Nomor Invoice --</span> 
                                        <i class="fa-solid fa-chevron-down text-[10px] text-zinc-500"></i> 
                                    </div> 
                                    <div class="dropdown-options"> 
                                        @forelse($invoices as $inv) 
                                            <div class="option" data-value="{{ $inv->id }}" data-total="{{ $inv->total_amount }}"> 
                                                {{ $inv->invoice_number }} - {{ $inv->tenant->tenant_name }} 
                                            </div> 
                                        @empty
                                            <div class="option disabled text-zinc-400 italic">Belum ada invoice tersedia</div>
                                        @endforelse 
                                    </div>
                                    <input type="hidden" name="invoice_id" required> 
                                </div> 
                            </div> 
                            <div class="grid grid-cols-2 gap-4"> 
                                <div class="text-field"> 
                                    <label class="text-field-label text-left">Jumlah Bayar</label> 
                                    <input type="number" name="amount_paid" class="text-field-input" placeholder="0" required step="any"> 
                                    <p class="text-[9px] text-zinc-500 mt-1 italic text-left">Pilih invoice untuk melihat total.</p> 
                                </div> 
                                <div class="text-field"> 
                                    <label class="text-field-label text-left">Tanggal Bayar</label> 
                                    <input type="date" name="payment_date" class="text-field-input" value="{{ date('Y-m-d') }}" required> 
                                </div> 
                            </div> 
                            <div class="grid grid-cols-2 gap-4"> 
                                <div class="text-field"> 
                                    <label class="text-field-label text-left">Metode Pembayaran</label> 
                                    <div class="custom-dropdown"> 
                                        <div class="dropdown-selected"> <span class="placeholder">Bank Transfer</span> <i class="fa-solid fa-chevron-down text-[10px] text-zinc-500"></i> </div> 
                                        <div class="dropdown-options"> <div class="option">Bank Transfer</div> <div class="option">Cash</div> <div class="option">E-Wallet</div> </div> 
                                        <input type="hidden" name="paid_using" value="Bank Transfer"> 
                                    </div> 
                                </div> 
                                <div class="text-field"> 
                                    <label class="text-field-label text-left">Status Awal</label> 
                                    <div class="custom-dropdown"> 
                                        <div class="dropdown-selected"> <span class="placeholder">Pending</span> <i class="fa-solid fa-chevron-down text-[10px] text-zinc-500"></i> </div> 
                                        <div class="dropdown-options"> <div class="option" data-value="pending">Pending</div> <div class="option" data-value="rejected">Rejected</div> <div class="option" data-value="verified">Verified</div> </div> 
                                        <input type="hidden" name="status" value="pending"> 
                                    </div> 
                                </div> 
                            </div> 
                        </div>
                        <button type="submit" class="dark-brown-button w-full mt-2"> Simpan Pembayaran </button> 
                    </div> 
                </form> 
            </div> 
        </div> 
    </div>

    <div class="popup" id="delete-tariff"> 
        <div class="popup-overlay"></div> 
        <div class="popup-card popup-md"> 
            <div class="popup-close-wrapper"> <button class="popup-close"> <i class="fa-solid fa-xmark"></i> </button> </div> 
            <div class="popup-header">Hapus Pembayaran Ini?</div> 
            <div class="popup-body btn-delete-wrapper"> 
                <button id="confirm-delete-btn" class="light-brown-btn">Ya</button> 
                <button class="dark-brown-button" data-close="delete-tariff">Tidak</button> 
            </div> 
        </div> 
    </div> 

</div> 
@endsection