@extends('layouts.app') 

@section('content') 

<div class="min-h-screen"> 
    <div class="mb-10 flex flex-col md:flex-row md:items-end justify-between gap-4 pb-8"> 
        <div> 
            <h1 class="title-text">Log Audit</h1> 
            <p class="subtitle-text">Braga8 Utility Billing Management</p> 
        </div> 
        <div class="header-user"> 
            <div class="icon-wrapper" data-popup="notif-popup"> 
                <i class="fa-solid fa-bell"></i> 
                <span class="notif-dot"></span> 
            </div> 
            <div class="profile-container" data-popup="detail-profile-popup"> 
                <div class="profile-icon"> 
                    <i class="fa-solid fa-user text-2xl text-[#a04d30]"></i> 
                </div> 
            </div> 
        </div> 
    </div> 

    <div class="flex flex-col gap-6"> 
        <div class="toolbar"> 
            <form method="GET" action="{{ route('audit_logs.index') }}" class="flex items-center gap-2 relative"> 
                <div class="search-wrapper"> 
                    <input type="text" name="search" placeholder="Search History.." value="{{ request('search') }}" > 
                    <span> <i class="fa-solid fa-magnifying-glass"></i> </span> 
                </div> 
                <button type="button" class="dark-brown-button btn-small" id="filter-btn-trigger" > 
                    <i class="fa-solid fa-filter"></i> 
                </button> 

                <div class="hidden absolute mt-2 z-50 w-[260px] bg-white border border-zinc-200 rounded-2xl shadow-xl p-4" id="filter-dropdown" style="top: 100%;"> 
                    <div class="flex flex-col gap-4"> 
                        <div> 
                            <label class="text-xs font-semibold text-zinc-500 mb-1 block"> Activity </label> 
                            <select name="action" class="text-field-input"> 
                                <option value="">All Activity</option> 
                                <option value="created" {{ request('action') == 'created' ? 'selected' : '' }}> Created </option> 
                                <option value="updated" {{ request('action') == 'updated' ? 'selected' : '' }}> Updated </option> 
                                <option value="deleted" {{ request('action') == 'deleted' ? 'selected' : '' }}> Deleted </option> 
                            </select> 
                        </div> 

                        <div> 
                            <label class="text-xs font-semibold text-zinc-500 mb-1 block"> Category </label> 
                            <select name="category" class="text-field-input">
                                <option value="">All Category</option>
                                @foreach($categories as $category)
                                    <option value="{{ $category }}" {{ request('category') == $category ? 'selected' : '' }}>
                                        {{ ucfirst(str_replace('_', ' ', $category)) }} 
                                    </option>
                                @endforeach
                            </select>
                        </div> 
                        <button type="submit" class="dark-brown-button w-full"> Apply Filter </button> 
                    </div> 
                </div> 

            </form>
            
            <div class="green-btn btn-small"> 
                <span> {{ $logs->total() }} Total Events </span> 
            </div> 
        </div> 

        <div class="table-wrapper"> 
            <div class="table-card"> 
                <div class="table-card-header"> 
                    <div class="table-card-title"> 
                        <span class="value">System Activity Logs</span> 
                    </div> 
                    <div class="table-card-meta"> {{ $logs->count() }} Records </div> 
                </div> 
                <div class="overflow-x-auto"> 
                    <table class="table"> 
                        <thead> 
                            <tr> 
                                <th>User</th> 
                                <th>Activity</th> 
                                <th>Category</th> 
                                <th>Item</th> 
                                <th>Activity Time</th> 
                            </tr> 
                        </thead> 
                        <tbody> 
                            @forelse($logs as $index => $log) 
                            <tr> 
                                <td> 
                                    <div class="flex items-center gap-3"> 
                                        <div class="w-10 h-10 rounded-full bg-zinc-100 flex items-center justify-center"> 
                                            <i class="fa-solid fa-user text-zinc-500"></i> 
                                        </div> 
                                        <div class="flex flex-col"> 
                                            <span class="font-semibold"> {{ $log->user->name ?? 'System' }} </span> 
                                        </div> 
                                    </div> 
                                </td> 
                                <td> 
                                    @if($log->action == 'created') <div> Created </div> 
                                    @elseif($log->action == 'deleted') <div> Deleted </div> 
                                    @else <div> Updated </div> 
                                    @endif 
                                </td> 
                                <td> <span> {{ $log->table_label }} </span> </td> 
                                <td> <span> {{ $log->item_label }} </span> </td> 
                                <td> <div> {{ $log->created_at->format('d M Y') }} • {{ $log->created_at->format('H:i') }} </div> </td> 
                            </tr> 
                            @empty 
                            <tr> 
                                <td colspan="7" class="text-center py-10 text-zinc-400"> No audit logs available. </td> 
                            </tr> 
                            @endforelse 
                        </tbody> 
                    </table> 
                </div> 
            </div> 
        </div> 

        <div class="flex flex-col md:flex-row justify-between items-center gap-4 px-2">
            <div class="text-sm text-zinc-500">
                Showing <span class="text-white">{{ $logs->firstItem() }}</span> 
                to <span class="text-white">{{ $logs->lastItem() }}</span> 
                of <span class="text-white">{{ $logs->total() }}</span> results
            </div>

            <div class="braga-pagination">
                {{ $logs->links('pagination::bootstrap-4') }}
            </div>
        </div>
    </div> 

</div> 

<script> 
    const filterBtn = document.getElementById('filter-btn-trigger'); 
    const filterDropdown = document.getElementById('filter-dropdown'); 

    if (filterBtn && filterDropdown) {
        filterBtn.addEventListener('click', (e) => { 
            e.stopPropagation();
            filterDropdown.classList.toggle('hidden'); 
        }); 

        document.addEventListener('click', (e) => {
            if (!filterDropdown.contains(e.target) && e.target !== filterBtn) {
                filterDropdown.classList.add('hidden');
            }
        });
    }
</script> 
@endsection