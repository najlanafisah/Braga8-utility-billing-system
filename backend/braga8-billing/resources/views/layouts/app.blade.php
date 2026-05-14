<!DOCTYPE html>
<html lang="en">
<head>
   <meta charset="UTF-8">
   <meta name="viewport" content="width=device-width, initial-scale=1.0">
   <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
   <title>Braga8 Utility Billing</title>
   <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
   @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>


<body>
    <main>
        <aside class="sidebar">
            <div class="sidebar-logo">
                <img src="{{ asset('app-logo.svg') }}" class="logo-image" alt="Logo">
            </div>

            <a href="{{ route('dashboard') }}">
                <h1 @class([
                    'sidebar-title',
                    'active-title' => request()->routeIs('dashboard') 
                ])>Dashboard</h1>
            </a>
            <nav class="sidebar-nav custom-scrollbar">
                <div @class(['menu-group', 'active' => request()->routeIs(['tenants.*', 'units.*'])])>
                    <a href="#" class="menu-item">
                        <span><i class="fa-solid fa-shop"></i></span>
                        <span>Penyewa & Unit</span>
                    </a>
                    <div class="submenu">
                        <a href="{{ route('tenants.index') }}" @class(['active' => request()->routeIs('tenants.*')])>Daftar Penyewa</a>
                        <a href="{{ route('units.index') }}" @class(['active' => request()->routeIs('units.*')])>Daftar Unit</a>
                    </div>
                </div>

                <div @class(['menu-group', 'active' => request()->routeIs(['utility-meters.*', 'meter-readings.*'])])>
                    <a href="#" class="menu-item">
                        <span><i class="fa-solid fa-gear"></i></span>
                        <span>Utilitas</span>
                    </a>
                    <div class="submenu">
                        <a href="{{ route('utility-meters.index') }}" @class(['active' => request()->routeIs('utility-meters.*')])>Data Meter</a>
                        <a href="{{ route('meter-readings.index') }}" @class(['active' => request()->routeIs('meter-readings.*')])>Catatan Meter</a>
                    </div>
                </div>

                <div @class(['menu-group', 'active' => request()->routeIs(['tariffs.*', 'invoices.*'])])>
                    <a href="#" class="menu-item">
                        <span><i class="fa-solid fa-money-bill"></i></span>
                        <span>Tarif & Tagihan</span>
                    </a>
                    <div class="submenu">
                        <a href="{{ route('tariffs.index') }}" @class(['active' => request()->routeIs('tariffs.*')])>Pengaturan Tarif</a>
                        <a href="{{ route('invoices.index') }}" @class(['active' => request()->routeIs('invoices.*')])>Tagihan</a>
                    </div>
                </div>

                <div @class(['menu-group', 'active' => request()->routeIs(['payments.*'])])>
                    <a href="#" class="menu-item">
                        <span><i class="fa-solid fa-credit-card"></i></span>
                        <span>Pembayaran</span>
                    </a>
                    <div class="submenu">
                        <a href="{{ route('payments.index') }}" @class(['active' => request()->routeIs('payments.*')])>Riwayat Pembayaran</a>
                    </div>
                </div>

                <div class="menu-group">
                    <a href="{{ route('reports.index') }}" @class(['menu-item', 'active'=> request()->routeIs('reports.*')])>
                        <span><i class="fa-solid fa-list"></i></span>
                        <span>Laporan Pemakaian</span>
                    </a>
                </div>

                <div class="menu-group">
                    <a href="{{ route('complaints.index') }}" @class(['menu-item', 'active'=> request()->routeIs('complaints.*')])>
                        <span><i class="fa-solid fa-triangle-exclamation"></i></span>
                        <span>Keluhan</span>
                    </a>
                </div>

                <div class="menu-group">
                    <a href="{{ route('users.index') }}" @class(['menu-item', 'active' => request()->routeIs('users.*')])>
                        <span><i class="fa-solid fa-user"></i></span>
                        <span>Manajemen Pengguna</span>
                    </a>
                </div>

                <div class="menu-group">
                    <a href="{{ route('audit_logs.index') }}" @class(['menu-item', 'active' => request()->routeIs('audit_logs.*')])>
                        <span><i class="fa-solid fa-clock-rotate-left"></i></span>
                        <span>Log Audit</span>
                    </a>
                </div>

                <div class="menu-group">
                    <a href="{{ route('reminders.index') }}" @class(['menu-item', 'active' => request()->routeIs('reminders.*')])>
                        <span><i class="fa-solid fa-sliders"></i></span>
                        <span>Siklus Penagihan</span>
                    </a>
                </div>
            </nav>
        </aside>

        <div class="flex-1 flex flex-col">
            <div class="p-8 w-full">
                @yield('content')
            </div>
        </div>
    </main>
    
    <div class="popup" id="detail-profile-popup">
       <div class="popup-overlay"></div>
            <div class="popup-card popup-md">
                <div class="popup-close-wrapper">
                    <button class="popup-close"><i class="fa-solid fa-xmark"></i></button>
                </div>
                <div class="popup-header">Rincian Akun</div>
                <div class="popup-body user-account-info flex flex-col gap-10">
                    <div class="flex flex-row gap-4">
                        <div class="profile-container">
                            <div class="profile-icon">
                                <i class="fa-solid fa-user text-2xl text-[#a04d30]"></i>
                            </div>
                        </div>
                        <div class="user-info">
                            <p class="font-bold text-lg text-zinc-800">{{ auth()->user()->name }}</p>
                            <p class="text-zinc-500 text-sm">@ {{ auth()->user()->username }}</p>
                        </div>
                    </div>

                    <div class="grid grid-cols-2 gap-4">
                        <div class="detail-item">
                            <p>Tanggal Bergabung</p>
                            <p>{{ auth()->user()->created_at->format('d M Y') }}</p>
                        </div>
                        <div class="detail-item">
                            <p>Peran</p>
                            <p>{{ auth()->user()->role }}</p>
                        </div>
                        <div class="detail-item">
                            <p>Email</p>
                            <p>{{ auth()->user()->email }}</p>
                        </div>
                    </div>

                    <div class="flex gap-2">
                        <button class="green-btn flex-1" id="openEdit" data-popup="edit-profile-popup">
                            <span><i class="fa-solid fa-pen"></i></span> <span>Edit Akun</span>
                        </button>
                        
                        <form method="POST" action="{{ route('logout') }}" class="flex-1">
                            @csrf
                            <button type="submit" class="light-brown-btn w-full">
                                <span><i class="fa-solid fa-arrow-right-from-bracket"></i></span> <span>Logout</span>
                            </button>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="popup" id="edit-profile-popup">
        <div class="popup-overlay"></div>
        <div class="popup-card popup-md">
            <div class="popup-close-wrapper">
                <button class="popup-close"><i class="fa-solid fa-xmark"></i></button>
            </div>
            <div class="popup-header">Edit Akun</div>
            <div class="popup-body">
                <form method="post" action="{{ route('profile.update') }}" class="flex flex-col gap-6">
                    @csrf
                    @method('patch')
                    
                    <div class="flex flex-col">
                        <div class="text-field">
                            <label class="text-field-label">Nama</label>
                            <input type="text" name="name" class="text-field-input" value="{{ old('name', auth()->user()->name) }}" required>
                        </div>
                        <div class="text-field">
                            <label class="text-field-label">Email</label>
                            <input type="email" name="email" class="text-field-input" value="{{ old('email', auth()->user()->email) }}" required>
                        </div>
                    </div>

                    <button type="submit" class="light-brown-btn">
                        Perbarui Informasi Akun
                    </button>
                </form>
            </div>
        </div>
    </div>

    <div class="popup" id="notif-popup">
        <div class="popup-overlay"></div>
        <div class="popup-card popup-md">
            <div class="popup-close-wrapper">
                <button class="popup-close"><i class="fa-solid fa-xmark"></i></button>
            </div>
            <div class="popup-header">Pemberitahuan</div>
            <div class="popup-body">
                <div class="notification-wrapper">
                    @forelse(auth()->user()->customNotifications as $notif)
                        <div class="notification {{ $notif->read_at ? 'is-read' : 'is-unread' }}">
                            <div class="notif-box">
                                <div class="flex justify-between items-start mb-2">
                                    <div class="flex items-center gap-2">
                                        <i class="fa-solid {{ $notif->read_at ? 'fa-envelope-open text-zinc-500' : 'fa-envelope text-[#FA8327]' }} text-xs"></i>
                                        <h4 class="font-bold text-white text-sm">{{ $notif->title }}</h4>
                                    </div>
                                    
                                    <div class="notif-actions flex gap-3">
                                        @if(!$notif->read_at)
                                            <form action="{{ route('notifications.read', $notif->id) }}" class="read-notif-form">
                                                @csrf
                                                <button type="submit" class="text-zinc-500 hover:text-zinc-300 transition-colors hover:scale-110 transition-transform" title="Tandai Baca">
                                                    <i class="fa-solid fa-check text-xs"></i>
                                                </button>
                                            </form>
                                        @endif
                                        <form action="{{ route('notifications.destroy', $notif->id) }}" class="delete-notif-form">
                                            @csrf
                                            @method('DELETE')
                                            <button type="submit" class="text-zinc-500 hover:text-zinc-300 transition-colors hover:scale-110 transition-transform">
                                                <i class="fa-solid fa-trash-can text-xs"></i>
                                            </button>
                                        </form>
                                    </div>
                                </div>

                                <p class="notif-message">{{ $notif->message }}</p>
                                
                                <div class="mt-3 text-[10px] text-zinc-500 text-right italic">
                                    {{ $notif->created_at->diffForHumans() }}
                                </div>
                            </div>
                        </div>
                    @empty
                        <div class="py-16 text-center">
                            <div class="text-zinc-700 mb-3">
                                <i class="fa-solid fa-bell-slash text-4xl"></i>
                            </div>
                            <p class="text-zinc-500 text-sm italic">Belum ada pemberitahuan baru.</p>
                        </div>
                    @endforelse
                </div>
            </div>
        </div>
    </div>

    @stack('scripts')
</body>
</html>

