<?php

namespace App\Models;

use App\Traits\LogsActivity;
use Illuminate\Database\Eloquent\Model;

class Complaint extends Model

{
    use LogsActivity;
    
    protected $fillable = [
    'reported_by', 
    'role', 
    'report_date', 
    'status', 
    'description', 
    'solution',
    'image'
];
protected $casts = [
    'report_date' => 'date',
];
}
