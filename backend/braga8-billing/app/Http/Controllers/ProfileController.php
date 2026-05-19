<?php

namespace App\Http\Controllers;

use App\Http\Requests\ProfileUpdateRequest;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Redirect;
use Illuminate\View\View;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class ProfileController extends Controller
{
    public function edit(Request $request): View
    {
        return view('profile.edit', [
            'user' => $request->user(),
        ]);
    }

    public function update(ProfileUpdateRequest $request): RedirectResponse
    {
        // 1. Jalankan validasi ketat HANYA jika kolom password baru diisi oleh user
        if ($request->filled('password')) {
            $request->validate([
                'current_password' => ['required', 'current_password'],
                'password' => ['required', 'confirmed', Password::defaults()],
            ], [
                'current_password.current_password' => 'Password saat ini yang Anda masukkan salah.',
                'password.confirmed' => 'Konfirmasi password baru tidak cocok.',
            ]);
        }

        // 2. AMAN: Hanya ambil 'name' dan 'email' agar field password kosong tidak ikut merusak database
        $request->user()->fill($request->only(['name', 'email']));

        if ($request->user()->isDirty('email')) {
            $request->user()->email_verified_at = null;
        }

        // 3. Eksekusi Hashing Password jika user memang mengisinya
        if ($request->filled('password')) {
            $request->user()->password = Hash::make($request->input('password'));
        }

        // 4. Simpan semua perubahan ke database Braga 8
        $request->user()->save();

        return Redirect::back()->with('status', 'profile-updated');
    }

    public function destroy(Request $request): RedirectResponse
    {
        $request->validateWithBag('userDeletion', [
            'password' => ['required', 'current_password'],
        ]);

        $user = $request->user();

        Auth::logout();

        $user->delete();

        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return Redirect::to('/');
    }
}