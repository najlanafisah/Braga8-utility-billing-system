@extends('layouts.app')

@section('content')
<div class="min-h-screen">
    <div class="mb-10 flex flex-col md:flex-row md:items-end justify-between gap-4 pb-8">
        <div>
            <h1 class="title-text">Meter Readings</h1>
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
        @if(session('success'))
            <div class="mb-4 p-4 bg-emerald-500 text-white rounded-xl font-bold shadow-lg">
                {{ session('success') }}
            </div>
        @endif

        <div class="toolbar mb-6">
            <form action="{{ route('meter-readings.index') }}" method="GET" class="search-wrapper">
                <input type="text" name="search" value="{{ request('search') }}" placeholder="Search Tenant / Unit...">
                <i class="fa-solid fa-magnifying-glass"></i>
            </form>
            <div class="toolbar-action">
                <button class="light-brown-btn btn-small" data-popup="addMeterModal">
                    <span><i class="fa-solid fa-plus"></i></span>
                    <span>Add Reading</span>
                </button>
            </div>
        </div>

        <div class="table-wrapper">
            @forelse($tenants as $tenant)
                <div class="table-card mb-8">
                    <div class="table-card-header">
                        <div class="table-card-title">
                            <span class="label">Tenant:</span>
                            <span class="value">{{ $tenant->tenant_name }}</span>
                        </div>
                        <div class="table-card-meta">
                            {{ $tenant->units->count() }} Unit(s)
                        </div>
                    </div>

                    <table class="table">
                        <thead>
                            <tr>
                                <th>Unit</th>
                                <th>Meter Number</th>
                                <th>Type</th>
                                <th>Reading Value</th>
                                <th>Recorded By</th>
                                <th class="text-center">Confirm</th>
                                <th>Date</th>
                                <th class="text-center">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            @php $anyReading = false; @endphp {{-- Penanda apakah ada data yang tampil --}}

                            @foreach($tenant->units as $unit)
                                @foreach($unit->meters as $meter)
                                    @forelse($meter->readings as $reading)
                                        @php $anyReading = true; @endphp
                                        <tr>
                                            <td>{{ $unit->unit_number }}</td>
                                            <td>{{ $meter->meter_number }}</td>
                                            <td>
                                                @if($meter->meter_type == 'electricity')
                                                    <span class="dark-green-btn">Electricity</span>
                                                @else
                                                    <span class="blue-btn">Water</span>
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
                                                        <button class="light-green-btn-action" 
                                                                data-popup="photoModal" 
                                                                onclick="showImage('{{ asset('storage/'.$reading->photo_path) }}', '{{ $unit->unit_number }}')">
                                                            <i class="fa-regular fa-eye"></i> View Image
                                                        </button>
                                                    @else
                                                        <span class="subtitle-text text-xs">No Photo</span>
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
                                            <p class="subtitle-text">Belum ada data meter untuk tenant ini.</p>
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
                    <h3 class="text-zinc-600 font-semibold">No Readings Found</h3>
                </div>
            @endforelse
        </div>
    </div>
</div>

<div class="popup" id="addMeterModal">
    <div class="popup-overlay"></div>
    <div class="popup-card popup-md">
        <div class="popup-close-wrapper">
            <button class="popup-close" data-close="addMeterModal">
                <i class="fa-solid fa-xmark"></i>
            </button>
        </div>
        <div class="popup-header">Add Meter Reading</div>
        <div class="popup-body">
            <form id="meterForm" action="{{ route('meter-readings.store') }}" method="POST" enctype="multipart/form-data">
                @csrf
                <input type="hidden" name="latitude" id="lat">
                <input type="hidden" name="longitude" id="lng">

                <div class="flex flex-col gap-6">
                    <div class="text-field">
                        <label class="text-field-label">Target Meter Unit</label>
                        <div class="custom-dropdown" id="meterDropdown">
                            <div class="dropdown-selected">
                                <span class="placeholder">-- Select Meter --</span>
                                <i class="fa-solid fa-chevron-down text-xs"></i>
                            </div>
                            <div class="dropdown-options">
                                @foreach($meters as $meter)
                                    <div class="option" data-value="{{ $meter->id }}">
                                        {{ $meter->unit->unit_number ?? '-' }} - {{ ucfirst($meter->meter_type) }} - {{ $meter->meter_number }}
                                    </div>
                                @endforeach
                            </div>
                            <input type="hidden" name="meter_id" id="meter_id_input" required>
                        </div>
                    </div>

                    <div class="text-field">
                        <label class="text-field-label">Reading Value</label>
                        <input type="number" step="0.01" name="reading_value" class="text-field-input" placeholder="0.00" required>
                    </div>

                    <div class="text-field">
                        <label class="text-field-label">Notes (Optional)</label>
                        <textarea name="description" rows="2" class="text-field-input" placeholder="Add some notes..."></textarea>
                    </div>

                    <div class="text-field">
                        <label class="text-field-label">Photo Evidence</label>
                        <div class="relative">
                            <input type="file" name="photo" id="photoInput" accept="image/*" class="hidden" required onchange="document.getElementById('file-name').innerText = this.files[0].name">
                            <label for="photoInput" class="flex items-center justify-between p-4 bg-white/5 border border-white/10 rounded-xl cursor-pointer hover:bg-white/10 transition-all">
                                <span id="file-name" class="text-zinc-500 text-sm">Choose image...</span>
                                <i class="fa-solid fa-camera text-[#a04d30]"></i>
                            </label>
                        </div>
                    </div>

                    <button type="submit" id="submitBtn" class="dark-brown-button w-full py-4">
                        <span id="btnText">Save Reading</span>
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<div class="popup" id="photoModal">
    <div class="popup-overlay"></div>
    <div class="popup-card popup-lg">
        <div class="popup-close-wrapper">
            <button class="popup-close" data-close="photoModal">
                <i class="fa-solid fa-xmark"></i>
            </button>
        </div>
        <div class="popup-header">
            <h2 id="modalUnitTitle">Unit -</h2>
            <p class="subtitle-text">Meter Reading Evidence</p>
        </div>
        <div class="popup-body flex flex-col items-center gap-4">
            <div class="w-full overflow-hidden rounded-2xl border border-white/20">
                <img id="modalImage" src="" alt="Meter Reading" class="w-full h-auto object-cover">
            </div>
            <button class="light-grey-btn" data-close="photoModal">Close</button>
        </div>
    </div>
</div>

<script>
    function showImage(src, unit) {
        document.getElementById('modalImage').src = src;
        document.getElementById('modalUnitTitle').innerText = "Unit " + unit;
    }

    const form = document.getElementById('meterForm');
    const btn = document.getElementById('submitBtn');
    const btnText = document.getElementById('btnText');

    form.addEventListener('submit', function(e) {
        e.preventDefault();
        
        if(!document.getElementById('meter_id_input').value) {
            alert("Silahkan pilih unit meter terlebih dahulu.");
            return;
        }

        btn.disabled = true;
        btnText.innerHTML = '<i class="fa-solid fa-satellite-dish fa-spin mr-2"></i> Satelite Sync...';

        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                function(position) {
                    document.getElementById('lat').value = position.coords.latitude;
                    document.getElementById('lng').value = position.coords.longitude;
                    btnText.innerText = "Uploading Data...";
                    form.submit();
                },
                function(error) {
                    alert("Gagal ambil lokasi. Pastikan GPS aktif.");
                    btn.disabled = false;
                    btnText.innerText = "Save Reading";
                },
                { enableHighAccuracy: true, timeout: 10000 }
            );
        } else {
            form.submit();
        }
    });
</script>
@endsection