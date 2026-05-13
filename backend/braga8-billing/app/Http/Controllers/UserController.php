<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;

class UserController extends Controller
{
   public function index(Request $request)
{
    $search = $request->input('search');
    $role = $request->input('role', 'admin');

    $users = User::when($search, function ($query, $search) {
            return $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('username', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        })
        ->when($role, function ($query, $role) {
            return $query->where('role', $role);
        })
        ->latest()
        ->paginate(10)
        ->withQueryString();

    return view('users.index', compact('users', 'role'));
}

    public function create()
    {
        return view('users.create');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required',
            'username' => 'required|unique:users',
            'email' => 'required|email|unique:users',
            'phone_number' => 'nullable|string|max:20',
            'role' => 'required|in:admin,supervisor,petugas,tenant',
            'password' => 'required|min:6',
        ]);

        $validated['password'] = bcrypt($validated['password']);

        User::create($validated);

        return redirect()->back()->with('status', 'user-stored');
    }

    public function show(User $user)
    {
        return view('users.show', compact('user'));
    }

    public function edit(User $user)
    {
        return view('users.edit', compact('user'));
    }

    public function update(Request $request, User $user)
{
    $validated = $request->validate([
        'name' => 'required',
        'username' => "required|unique:users,username,$user->id",
        'email' => "required|email|unique:users,email,$user->id",
        'phone_number' => 'nullable|string|max:20',
        'role' => 'required|in:admin,supervisor,petugas,tenant',
        'password' => 'nullable|min:6', // Tambahkan validasi nullable di sini
    ]);

    if ($request->filled('password')) {
        $validated['password'] = bcrypt($request->password);
    } else {
        unset($validated['password']);
    }

    $user->update($validated);

    return redirect()->back()->with('status', 'user-updated');
}

    public function destroy(User $user)
    {
        $user->delete();
        return redirect()->back()->with('status', 'user-deleted');
    }
}