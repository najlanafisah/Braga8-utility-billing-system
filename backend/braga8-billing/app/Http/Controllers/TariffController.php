<?php

namespace App\Http\Controllers;

use App\Models\Tariff;
use Illuminate\Http\Request;

class TariffController extends Controller
{
   
public function index(Request $request)
{
    $query = Tariff::query();

    if ($request->filled('search')) {
        $search = $request->search;
        $query->where('name', 'LIKE', "%{$search}%");
    }

    $tariffs = $query->latest()->get();
    return view('tariffs.index', compact('tariffs'));
}

public function store(Request $request)
{
    $validated = $request->validate([
        'name'           => 'required|string|max:255',
        'water_price'    => 'required|numeric',
        'electric_price' => 'required|numeric',
        'tax_percent'    => 'required|numeric',
        'other_fees'     => 'nullable|array',
    ]);

    $saved = Tariff::create($validated);
    
    if ($saved) {
        return redirect()->route('tariffs.index')->with('status', 'tariff-stored');
    }
    return back()->with('error', 'Something went wrong.');
}

public function create()
{
    return view('tariffs.create');
}

public function edit(Tariff $tariff)
{
    return view('tariffs.edit', compact('tariff'));
}

public function update(Request $request, Tariff $tariff)
{
    $validated = $request->validate([
        'name'           => 'required|string|max:255',
        'water_price'    => 'required|numeric',
        'electric_price' => 'required|numeric',
        'tax_percent'    => 'nullable|numeric',
        'other_fees'     => 'nullable|array',
    ]);

    $tariff->update($validated);
    
    return redirect()->route('tariffs.index')->with('status', 'tariff-updated');
}

public function destroy(Tariff $tariff) {
    $tariff->delete();
    
    return back()->with('status', 'tariff-deleted');
}

public function show(Tariff $tariff)
{
    return view('tariffs.show', compact('tariff'));
}

}

