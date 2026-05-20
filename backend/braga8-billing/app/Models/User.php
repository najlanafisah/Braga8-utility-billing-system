<?php

namespace App\Models;

use App\Traits\LogsActivity;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use LogsActivity;
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * Properti mass-assignment agar kolom ini diizinkan diisi lewat User::create()
     */
    protected $fillable = [
        'name',
        'username',
        'email',
        'password',
        'phone_number',
        'role',
    ];

    /**
     * Relasi ke data riwayat pencatatan meteran utilitas
     */
    public function meterReadings() 
    {
        return $this->hasMany(MeterReading::class);
    }

    /**
     * Relasi ke data Profile Tenant milik User ini
     */
    public function tenant()
    {
        return $this->hasOne(Tenant::class, 'user_id');
    }

    /**
     * Relasi ke sistem Notifikasi custom di aplikasi Braga8
     */
    public function customNotifications()
    {
        return $this->hasMany(Notification::class, 'user_id')->latest();
    }
}