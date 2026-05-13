<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\{
    AuditLogController,
    Auth\RegisteredUserController,
    ProfileController,
    DashboardController,
    UserController,
    TenantController,
    UnitController,
    MeterReadingController,
    TariffController,
    InvoiceController,
    PaymentController,
    UtilityMeterController,
    ReminderController,
    UsageReportController,
    ComplaintController,
    NotificationController
};

Route::get('/', function () {
    return view('welcome');
});

Route::middleware('guest')->group(function () {
    Route::get('register', [RegisteredUserController::class, 'create'])->name('register');
    Route::post('register', [RegisteredUserController::class, 'store']);
});

Route::middleware(['auth', 'verified'])->group(function () {
    
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');
    Route::prefix('profile')->group(function () {
        Route::get('/', [ProfileController::class, 'edit'])->name('profile.edit');
        Route::patch('/', [ProfileController::class, 'update'])->name('profile.update');
        Route::delete('/', [ProfileController::class, 'destroy'])->name('profile.destroy');
    });

    Route::get('/audit-logs', [AuditLogController::class, 'index'])->name('audit_logs.index');
    Route::delete('/audit-logs/clear', [AuditLogController::class, 'clear'])->name('audit_logs.clear');

    Route::resource('users', UserController::class);
    Route::resource('tenants', TenantController::class);
    Route::resource('units', UnitController::class);
    Route::resource('utility-meters', UtilityMeterController::class);
    Route::resource('meter-readings', MeterReadingController::class);
    Route::resource('tariffs', TariffController::class);
    Route::resource('invoices', InvoiceController::class);
    Route::resource('reminders', ReminderController::class);
    Route::resource('payments', PaymentController::class);
    Route::resource('complaints', ComplaintController::class);


    Route::get('invoices/{invoice}/pdf', [InvoiceController::class, 'pdf'])->name('invoices.pdf');
    Route::get('invoices/{invoice}/notify', [InvoiceController::class, 'notifyTenant'])->name('invoices.notify');

    Route::patch('/meter-readings/{id}/status', [MeterReadingController::class, 'updateStatus'])
        ->name('meter-readings.update-status');

    Route::prefix('reports')->group(function () {
        Route::get('/', [UsageReportController::class, 'index'])->name('reports.index');
        Route::post('/generate', [UsageReportController::class, 'generate'])->name('reports.generate');
        Route::get('/{id}/pdf', [UsageReportController::class, 'exportPdf'])->name('reports.pdf');
    });

    Route::post('/payments/{payment}/remind', [PaymentController::class, 'remind'])->name('payments.remind');

    Route::post('complaints/{complaint}/action', [ComplaintController::class, 'action'])->name('complaints.action');

    Route::get('/notifications', [NotificationController::class, 'index'])->name('notifications.index');
    Route::post('/notifications/{notification}/read', [NotificationController::class, 'markAsRead'])->name('notifications.read');
    Route::delete('/notifications/{notification}', [NotificationController::class, 'destroy'])->name('notifications.destroy');
});

require __DIR__.'/auth.php';