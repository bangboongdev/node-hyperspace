#!/bin/bash

# Hiển thị tiêu đề
clear
echo "               ĐĂNG KÝ KÊNH CỦA TÔI                     "

sleep 1

echo "Đang dừng aios-cli đang chạy để tránh lỗi..."
aios-cli kill
sleep 1

echo "Hiển thị danh sách các screen hiện có..."
screen -ls | grep -o '[0-9]*\.' | nl -s '. ' | while read line; do
    screen_id=$(echo $line | awk '{print $2}')
    screen_name=$(screen -ls | grep -E "^\s*$screen_id" | awk -F. '{print $2}')
    echo "$screen_id. $screen_name"
done
sleep 1

read -p "Bạn có muốn xóa các screen hiện có không? (y/n): " delete_choice
if [[ "$delete_choice" == "y" || "$delete_choice" == "Y" ]]; then
    read -p "Nhập số thứ tự của screen cần xóa (cách nhau bằng dấu phẩy nếu nhiều): " screens_to_delete
    IFS=',' read -ra screens_array <<< "$screens_to_delete"
    
    for screen_number in "${screens_array[@]}"; do
        screen_number=$(echo "$screen_number" | xargs)
        screen_info=$(screen -ls | grep -o '[0-9]*\.' | nl -s '. ' | sed -n "${screen_number}p")
        screen_id=$(echo "$screen_info" | awk '{print $2}')
        screen_name=$(screen -ls | grep -E "^\s*$screen_id" | awk -F. '{print $2}')
        
        if [ -n "$screen_id" ]; then
            echo "Đang xóa screen '$screen_name' với ID '$screen_id'..."
            screen -S "$screen_id" -X quit
            echo "Screen '$screen_name' đã được xóa thành công."
        else
            echo "[LỖI] Không tìm thấy screen với số thứ tự '$screen_number'."
        fi
    done
fi

sleep 2

read -p "Bạn có muốn xóa các model đã tải trước đó không? (y/n): " delete_model_choice
if [[ "$delete_model_choice" == "y" || "$delete_model_choice" == "Y" ]]; then
    echo "Đang xóa các model đã tải trước đó..."
    rm -rf /root/.cache/hyperspace/models/*
    sleep 1
fi

read -p "Bạn có muốn nhập private key bây giờ không? (y/n): " choice
if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
    echo "Nhập private key của bạn (nhấn ENTER và sau đó nhấn CTRL+D):"
    cat > .pem
else
    echo "Bỏ qua bước này."
fi

clear

read -p "Nhập tên cho screen: " screen_name

if [[ -z "$screen_name" ]]; then
    echo "Tên screen không được để trống."
    exit 1
fi

echo "Tạo phiên screen với tên '$screen_name'..."
screen -S "$screen_name" -dm
echo "[THÔNG TIN] Phiên screen '$screen_name' đã được tạo."

echo "Chạy lệnh 'aios-cli start' trong phiên screen '$screen_name'..."
screen -S "$screen_name" -X stuff "aios-cli start\n"

sleep 1

echo "Thoát khỏi phiên screen '$screen_name'..."
screen -S "$screen_name" -X detach
sleep 1

if [[ $? -eq 0 ]]; then
    echo "[THÀNH CÔNG] Screen '$screen_name' đã được tạo và chạy lệnh aios-cli start."
else
    echo "[LỖI] Không thể tạo screen."
    exit 1
fi

sleep 2

read -p "Bạn có muốn tải model mới không? (y/n): " download_model_choice
if [[ "$download_model_choice" == "y" || "$download_model_choice" == "Y" ]]; then
    echo "Đang thêm model với lệnh aios-cli models add..."
    url="https://huggingface.com/afrideva/Tiny-Vicuna-1B-GGUF/resolve/main/tiny-vicuna-1b.q8_0.gguf"
    model_folder="/root/.cache/hyperspace/models/hf__afrideva___Tiny-Vicuna-1B-GGUF__tiny-vicuna-1b.q8_0.gguf"
    model_path="$model_folder/tiny-vicuna-1b.q8_0.gguf"

    if [[ ! -d "$model_folder" ]]; then
        echo "Thư mục không tồn tại, tạo thư mục $model_folder..."
        mkdir -p "$model_folder"
    else
        echo "Thư mục đã tồn tại, tiếp tục..."
    fi

    if [[ ! -f "$model_path" ]]; then
        echo "Đang tải model từ $url..."
        wget -q --show-progress "$url" -O "$model_path"
        if [[ -f "$model_path" ]]; then
            echo "[THÀNH CÔNG] Model đã được tải và lưu tại $model_path!"
        else
            echo "[LỖI] Có lỗi xảy ra khi tải model."
        fi
    else
        echo "[THÔNG TIN] Model đã tồn tại tại $model_path, bỏ qua tải."
    fi
else
    echo "[THÔNG TIN] Bỏ qua bước tải model."
fi

echo "[THÀNH CÔNG] Model đã được thêm!"
echo "Đợi đến khi hoàn tất!"
read -p "Bạn có muốn chạy inferencing? (y/n): " user_choice

if [[ "$user_choice" == "y" || "$user_choice" == "Y" ]]; then
    infer_prompt="SHARE IT HUB là gì? Mô tả cộng đồng airdrop."
    echo "[THÔNG TIN] Bắt đầu inferencing với prompt: '$infer_prompt'"
    if aios-cli infer --model hf:afrideva/Tiny-Vicuna-1B-GGUF:tiny-vicuna-1b.q8_0.gguf --prompt "$infer_prompt"; then
        echo "[THÀNH CÔNG] Inferencing hoàn tất."
    else
        echo "[LỖI] Có lỗi xảy ra khi inferencing."
    fi
else
    echo "[THÔNG TIN] Bỏ qua bước inferencing."
fi

echo "Chạy lệnh import-keys với file .pem..."
aios-cli hive import-keys ./.pem

sleep 1

echo "Đăng nhập Hive..."
aios-cli hive login
sleep 1

echo "Sử dụng Tier 5..."
aios-cli hive select-tier 5
sleep 1

echo "Kết nối Hive..."
aios-cli hive connect
sleep 1

read -p "Bạn có muốn chạy Hive inferencing không? (y/n): " hive_choice

if [[ "$hive_choice" == "y" || "$hive_choice" == "Y" ]]; then
    infer_prompt="SHARE IT HUB là gì? Mô tả cộng đồng airdrop."
    echo "[THÔNG TIN] Đừng quên đăng ký kênh YouTube và Telegram: SHARE IT HUB."
    if aios-cli hive infer --model hf:afrideva/Tiny-Vicuna-1B-GGUF:tiny-vicuna-1b.q8_0.gguf --prompt "$infer_prompt"; then
        echo "[THÀNH CÔNG] Hive Inferencing hoàn tất."
    else
        echo "[LỖI] Có lỗi xảy ra khi Hive Inferencing."
    fi
else
    echo "[THÔNG TIN] Bỏ qua bước Hive Inferencing."
fi

sleep 1

echo "Đang khởi động lại aios-cli và kết nối lại..."
screen -S "$screen_name" -X stuff "aios-cli start
