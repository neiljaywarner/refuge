import os
import subprocess
import time
import sys

LEFT_DEV = "56091JEBF14039"
RIGHT_DEV = "58221JEBF20835"

def adb(dev, *args):
    cmd = ["adb", "-s", dev] + list(args)
    return subprocess.check_output(cmd).decode('utf-8', errors='ignore')

def adb_shell(dev, cmd_str):
    res = subprocess.run(["adb", "-s", dev, "shell", cmd_str], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return res.stdout.decode('utf-8', errors='ignore')

def take_screenshot(dev, dest_path):
    os.makedirs(os.path.dirname(dest_path), exist_ok=True)
    subprocess.run(["adb", "-s", dev, "exec-out", "screencap", "-p"], stdout=open(dest_path, "wb"))

def type_text(dev, text):
    escaped = text.replace(" ", "%s").replace("'", "\\'").replace('"', '\\"').replace("(", "\\(").replace(")", "\\)").replace("[", "\\[").replace("]", "\\]")
    adb_shell(dev, f"input text '{escaped}'")

def install_apk():
    apk_path = "build/app/outputs/flutter-apk/app-release.apk"
    print(f"Installing {apk_path} on both devices...")
    for dev in [LEFT_DEV, RIGHT_DEV]:
        print(f"Installing on {dev}...")
        subprocess.run(["adb", "-s", dev, "install", "-r", apk_path], check=True)
    print("APKs installed successfully.")

def main():
    install_apk()

    print("=== Step 0: Initializing and resetting app state ===")
    for dev in [LEFT_DEV, RIGHT_DEV]:
        adb_shell(dev, "pkill -f screenrecord 2>/dev/null || true")
        adb_shell(dev, "logcat -c")
        adb_shell(dev, "rm -f /sdcard/left_pixel_staggered.mp4 /sdcard/right_pixel_staggered.mp4")
        adb_shell(dev, "am force-stop com.belongonthespectrum.sanctuary")
        time.sleep(1)
        adb_shell(dev, "monkey -p com.belongonthespectrum.sanctuary -c android.intent.category.LAUNCHER 1")
    
    time.sleep(4)
    take_screenshot(LEFT_DEV, "scratch/step0_initial_left.png")
    take_screenshot(RIGHT_DEV, "scratch/step0_initial_right.png")
    print("Initial screens captured.")

    # Start logcat in background
    left_log_file = open("scratch/left_pixel_demo.log", "w")
    right_log_file = open("scratch/right_pixel_demo.log", "w")
    left_log_proc = subprocess.Popen(["adb", "-s", LEFT_DEV, "logcat", "-v", "time", "*:I"], stdout=left_log_file)
    right_log_proc = subprocess.Popen(["adb", "-s", RIGHT_DEV, "logcat", "-v", "time", "*:I"], stdout=right_log_file)

    print("=== Starting Screen Recordings on Both Pixels (50 seconds) ===")
    left_rec = subprocess.Popen(["adb", "-s", LEFT_DEV, "shell", "screenrecord", "--time-limit", "50", "--bit-rate", "8000000", "/sdcard/left_pixel_staggered.mp4"])
    right_rec = subprocess.Popen(["adb", "-s", RIGHT_DEV, "shell", "screenrecord", "--time-limit", "50", "--bit-rate", "8000000", "/sdcard/right_pixel_staggered.mp4"])
    
    time.sleep(3)

    ts_now = time.strftime("%H:%M:%S")
    right_msg = f"[{ts_now} LTE] Unhurried reflection via Serverpod Cloud!"

    print(f"=== Step 1: Right Pixel taps text box and types reflection with timestamp {ts_now} ===")
    adb_shell(RIGHT_DEV, "input tap 500 1050")
    time.sleep(1)
    type_text(RIGHT_DEV, right_msg)
    time.sleep(1.2)
    take_screenshot(RIGHT_DEV, "scratch/step1_right_typed.png")

    print("=== Step 2: Right Pixel closes keyboard ===")
    adb_shell(RIGHT_DEV, "input keyevent 4")
    time.sleep(1.5)
    take_screenshot(RIGHT_DEV, "scratch/step2_right_keyboard_closed.png")

    print("=== Step 3: Right Pixel taps Publish Reflection ===")
    adb_shell(RIGHT_DEV, "input tap 801 1268")
    time.sleep(1.5)
    take_screenshot(RIGHT_DEV, "scratch/step3_right_published.png")

    print("=== Step 4: Left Pixel observes real-time incoming post ===")
    time.sleep(3.5)
    take_screenshot(LEFT_DEV, "scratch/step4_left_received.png")

    print("=== Step 5: Left Pixel adds Praying affirmation reaction ===")
    adb_shell(LEFT_DEV, "input tap 184 1889")
    time.sleep(1.5)
    take_screenshot(LEFT_DEV, "scratch/step5_left_reacted.png")

    ts_reply = time.strftime("%H:%M:%S")
    left_msg = f"[{ts_reply} LTE] Received! Praise God for calm tech."

    print(f"=== Step 6: Left Pixel composes reply reflection at {ts_reply} ===")
    adb_shell(LEFT_DEV, "input tap 500 1050")
    time.sleep(1)
    type_text(LEFT_DEV, left_msg)
    time.sleep(1.2)
    take_screenshot(LEFT_DEV, "scratch/step6_left_reply_typed.png")

    print("=== Step 7: Left Pixel closes keyboard ===")
    adb_shell(LEFT_DEV, "input keyevent 4")
    time.sleep(1.5)
    take_screenshot(LEFT_DEV, "scratch/step7_left_keyboard_closed.png")

    print("=== Step 8: Left Pixel taps Publish Reflection ===")
    adb_shell(LEFT_DEV, "input tap 801 1268")
    time.sleep(2)
    take_screenshot(LEFT_DEV, "scratch/step8_left_published.png")

    print("=== Step 9: Right Pixel receives reply live ===")
    time.sleep(3.5)
    take_screenshot(RIGHT_DEV, "scratch/step9_right_received.png")

    print("=== Step 10: Right Pixel taps Support reaction on new post ===")
    adb_shell(RIGHT_DEV, "input tap 433 1889")
    time.sleep(1.5)
    take_screenshot(RIGHT_DEV, "scratch/step10_right_support.png")

    print("=== Step 11: Right Pixel demonstrates Sensory Theme toggle ===")
    adb_shell(RIGHT_DEV, "input tap 912 226")
    time.sleep(1.2)
    take_screenshot(RIGHT_DEV, "scratch/step11_theme_menu.png")
    # Tap 3rd item in popup menu (Monastic Dark)
    adb_shell(RIGHT_DEV, "input tap 800 480")
    time.sleep(2)
    take_screenshot(RIGHT_DEV, "scratch/step11_theme_applied.png")

    print("=== Step 12: Left Pixel demonstrates About / Info dialog ===")
    adb_shell(LEFT_DEV, "input tap 1027 225")
    time.sleep(2)
    take_screenshot(LEFT_DEV, "scratch/step12_about_dialog.png")
    # Tap outside to dismiss
    adb_shell(LEFT_DEV, "input tap 540 1900")
    time.sleep(1.5)

    print("Waiting for screen recordings to complete...")
    left_rec.wait()
    right_rec.wait()
    time.sleep(2)

    # Terminate logcats
    left_log_proc.terminate()
    right_log_proc.terminate()
    left_log_file.close()
    right_log_file.close()

    print("=== Pulling completed videos ===")
    subprocess.run(["adb", "-s", LEFT_DEV, "pull", "/sdcard/left_pixel_staggered.mp4", "sanctuary_pixel_left_staggered.mp4"])
    subprocess.run(["adb", "-s", RIGHT_DEV, "pull", "/sdcard/right_pixel_staggered.mp4", "sanctuary_pixel_right_staggered.mp4"])
    print("Videos pulled successfully!")

if __name__ == "__main__":
    main()
