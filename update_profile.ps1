$script = @"
<script>
    document.addEventListener('DOMContentLoaded', () => {
        const userName = localStorage.getItem('eams_user_name');
        const userDivision = localStorage.getItem('eams_user_division');
        const userRole = localStorage.getItem('eams_user_role');
        
        if (userName) {
            const nameEl = document.getElementById('sidebarUserName');
            if (nameEl) nameEl.textContent = userName;
            
            const avatarEl = document.getElementById('sidebarUserAvatar');
            if (avatarEl) {
                const initials = userName.split(' ').map(n => n[0]).join('').substring(0,2).toUpperCase();
                avatarEl.textContent = initials;
            }
        }
        if (userDivision) {
            const roleEl = document.getElementById('sidebarUserRole');
            if (roleEl) {
                if (userRole === 'admin') {
                    roleEl.textContent = 'Admin - ' + userDivision;
                } else {
                    roleEl.textContent = 'Staff - ' + userDivision;
                }
            }
        }
    });
</script>
</body>
"@

Get-ChildItem -Filter *.html | ForEach-Object {
    if ($_.Name -ne 'login.html') {
        $content = Get-Content $_.FullName -Raw
        
        # Replace John Doe and JD with IDs
        $content = $content -replace '<p class="text-sm font-medium text-white">John Doe</p>', '<p id="sidebarUserName" class="text-sm font-medium text-white">John Doe</p>'
        $content = $content -replace '<p class="text-xs text-slate-400">Chief Financial Officer</p>', '<p id="sidebarUserRole" class="text-xs text-slate-400">Chief Financial Officer</p>'
        $content = $content -replace '<div class="w-10 h-10 rounded-full bg-blue-500 flex items-center justify-center text-white font-bold mr-3">\s*JD\s*</div>', '<div id="sidebarUserAvatar" class="w-10 h-10 rounded-full bg-blue-500 flex items-center justify-center text-white font-bold mr-3">JD</div>'
        
        # Add the script just before </body>
        if ($content -notmatch 'sidebarUserName') {
           # maybe already has it
        }
        $content = $content -replace '</body>', $script
        Set-Content $_.FullName $content -Encoding UTF8
    }
}
