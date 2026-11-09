RIKIPATH — Sakura Time-of-Day Hero Banners
=========================================

Reference size: 2048 x 682 pixels, approximately 3:1.
All 5 images are distinct landscape artwork and have NO embedded headline.
Use the 5 optimized .webp images in Flutter; .png originals are also included.

sakura_morning | 05:00–10:59 | Sáng — bình minh, học từ vựng bên cửa sổ
sakura_noon | 11:00–13:59 | Trưa — dạo bước khám phá Nhật Bản, hứng khởi
sakura_afternoon | 14:00–17:59 | Chiều — quán học ven hồ, hoàng hôn ấm áp
sakura_evening | 18:00–21:59 | Tối — đèn đường và nhà gỗ bắt đầu sáng, đọc bài trong không gian hoàng hôn hồng tím
sakura_late_night | 22:00–04:59 | Khuya — yên tĩnh, trăng sao, học nhẹ nhàng

Implementation: Copy WEBP files to RikiPath.Mobile/assets/images/time_banners/. Configure pubspec.yaml, render full-bleed banner outside the default page horizontal Padding. Overlay VI/JA localized text in Flutter, with per-scene text colors and a gradient for contrast. Device-local time, update when resumed and at the next boundary, avoid per-second polling.
