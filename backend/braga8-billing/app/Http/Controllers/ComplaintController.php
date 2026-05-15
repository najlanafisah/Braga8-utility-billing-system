<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Complaint;
use Illuminate\Support\Facades\Storage;

class ComplaintController extends Controller
{
    public function index(Request $request) 
    {
        $query = Complaint::query();

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('reported_by', 'like', "%{$search}%")
                ->orWhere('description', 'like', "%{$search}%"); 
            });
        }

        $sort = $request->get('sort', 'latest');
        
        if ($sort === 'oldest') {
            $query->oldest();
        } else {
            $query->latest();
        }

        $complaints = $query->paginate(10)->appends($request->all());

        return view('complaints.index', compact('complaints'));
    }

    public function action(Request $request, Complaint $complaint) 
    {
        $request->validate([
            'solution' => 'required|string|min:5',
        ]);

        $complaint->update([
            'solution' => $request->solution,
            'status' => 'resolved',
        ]);

        return redirect()->back()->with('status', 'complaint-resolved');
    }

    public function destroy(Complaint $complaint) 
    {
        if($complaint->image) {
            Storage::disk('public')->delete($complaint->image);
        }
        
        $complaint->delete();
        
        return redirect()->back()->with('status', 'complaint-deleted');
    }
}