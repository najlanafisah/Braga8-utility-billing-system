# Braga8 Utility Billing Management System

Braga8 Utility Billing Management System (B8-UBMS) is a web-based utility billing management platform designed for multi-tenant properties such as apartments, commercial buildings, and rental complexes.

The system helps property management teams manage utility recording, billing generation, payment tracking, and operational monitoring through an integrated web and mobile platform.

Built with a focus on operational efficiency, transparency, and auditability, B8-UBMS supports role-based access management, digital billing workflows, offline field data collection, and automated payment reconciliation.

---

## Features

### Admin
- Manage units, tenants, and utility tariffs
- Verify meter readings submitted by field officers
- Generate monthly invoices automatically
- Monitor payment status and billing history
- Handle complaints and billing disputes
- Access audit log and activity history
- Manage penalties and billing adjustments

### Field Officer
- Record utility meter readings
- Upload meter photos as proof of inspection
- Access inspection task lists
- Report damaged or manipulated meters
- Offline data recording with sync support

### Tenant
- View utility usage history
- Access invoice details
- View uploaded meter photos
- Make digital payments
- Submit billing complaints or disputes

---

## Tech Stack

### Backend
- PHP
- Laravel

### Frontend
- HTML
- CSS
- Tailwind CSS
- JavaScript

### Mobile
- Flutter
- Dart

### Database
- MySQL

### Tools & Services
- Git
- GitHub
- REST API
- Payment Gateway Integration

---

## System Roles

| Role | Platform | Description |
|------|------|------|
| Admin / Supervisor | Web | Manage operational and billing processes |
| Field Officer | Mobile | Record meter readings and field inspections |
| Tenant | Mobile | Access bills, payments, and utility usage |

---

## Main Modules

- Authentication & Authorization
- Dashboard & Analytics
- Utility Meter Recording
- Billing & Invoice Management
- Payment Management
- Complaint Management
- Audit Log System
- Tenant Management
- Unit Management
- Offline Sync Support

---

## Installation

### Clone Repository

```bash
git clone https://github.com/your-username/braga8-utility-billing-management-system.git
```

### Move to Project Directory

```bash
cd braga8-utility-billing-management-system
```

### Install Dependencies

```bash
composer install
npm install
```

### Copy Environment File

```bash
cp .env.example .env
```

### Generate Application Key

```bash
php artisan key:generate
```

### Configure Database

Edit the `.env` file and update your database configuration.

```env
DB_DATABASE=braga8_db
DB_USERNAME=root
DB_PASSWORD=
```

### Run Migration

```bash
php artisan migrate
```

### Run Seeder (Optional)

```bash
php artisan db:seed
```

### Start Development Server

```bash
php artisan serve
```

### Run Frontend

```bash
npm run dev
```

---

## Project Structure

```bash
app/
database/
public/
resources/
routes/
storage/
```

---

## Future Improvements

- Real-time notification system
- AI-based usage anomaly detection
- Advanced financial reporting
- Multi-property support
- Export PDF & Excel reports
- GPS tracking for field officers

---

## Screenshots

<img width="1919" height="1199" alt="Screenshot 2026-05-24 100736" src="https://github.com/user-attachments/assets/2c72089d-b5c5-4552-b100-6d371d3b24b3" />

---

Live demo = https://youtu.be/2JTqn6F4Ulo?si=-Qaakd5X-Ed8nq5X

## Contributors

Developed by:
1. Quaneisha Syifa Nida
2. Najla Nafisah
3. Khansa Syahidah Aulia
4. Aluna Ekin Kehara
