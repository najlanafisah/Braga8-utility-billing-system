<?php

namespace App\Http\Controllers;

use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class NotificationController extends Controller
{
    public function markAsRead($notification)
    {
        $notif = \App\Models\Notification::where('user_id', auth()->id())->findOrFail($notification);
        $notif->update(['read_at' => now()]);

        if (request()->ajax()) {
            return response()->json(['success' => true]);
        }

        return back();
    }

    public function destroy($notification)
    {
        $notif = \App\Models\Notification::where('user_id', auth()->id())->findOrFail($notification);
        $notif->delete();

        if (request()->ajax()) {
            return response()->json(['success' => true]);
        }

        return back();
    }
}