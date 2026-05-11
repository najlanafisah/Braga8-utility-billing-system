<?php

namespace App\Http\Controllers;

use App\Models\AuditLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth as FacadesAuth;

class AuditLogController extends Controller
{
    public function index(Request $request)
    {
        $latestIds = AuditLog::latest()->limit(50)->pluck('id');

        AuditLog::whereNotIn('id', $latestIds)
            ->update(['is_archived' => true]);

        $query = AuditLog::with('user')
            ->where('is_archived', false);

        if ($request->search) {

            $search = $request->search;

            $query->where(function ($q) use ($search) {

                $q->where('action', 'like', "%{$search}%")

                    ->orWhereHas('user', function ($userQuery) use ($search) {

                        $userQuery->where('name', 'like', "%{$search}%");

                    });

            });

        }

        if ($request->has('category') && $request->category != '') {
            $query->where('table_name', $request->category);
        }

        $logs = $query->latest()->paginate(10);

        $categories = AuditLog::where('is_archived', false)
            ->select('table_name')
            ->distinct()
            ->pluck('table_name');

        return view('audit_logs.index', compact('logs', 'categories'));
    }

    public function apiIndex()
    {
        $logs = AuditLog::with('user')
            ->where('user_id', FacadesAuth::id())
            ->where('is_archived', false)
            ->latest()
            ->paginate(10);

        return response()->json($logs);
    }
}