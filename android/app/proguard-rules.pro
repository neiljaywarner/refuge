# Giphy SDK references kotlinx.parcelize.Parcelize. Release builds enable R8,
# and that missing class fails the APK. Same rule as the giphy_flutter_sdk example.
-dontwarn kotlinx.parcelize.Parcelize
