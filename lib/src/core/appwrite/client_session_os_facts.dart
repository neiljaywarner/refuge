/// OS name and version for a session-audit row.
///
/// [osVersion] is clipped later. This value is not a device identifier.
class const ClientSessionOsFacts({required final String osName, final String? osVersion});
