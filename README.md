# OpenBeach - Nền tảng Giao dịch NFT

Trong bối cảnh công nghệ Blockchain và tài sản số đang phát triển mạnh mẽ tại Việt Nam, chúng em nhận thấy thị trường NFT trong nước đang cần những ứng dụng chuyên nghiệp, dễ tiếp cận và được thiết kế phù hợp với người dùng Việt Nam. Đó là lý do chúng em quyết định phát triển NFT Marketplace - một nền tảng giao dịch NFT hoàn chỉnh bằng tiếng Việt.
Với niềm đam mê về công nghệ blockchain và mong muốn đưa NFT đến gần hơn với cộng đồng, chúng em tập trung xây dựng một nền tảng không chỉ đơn thuần là nơi mua bán NFT, mà còn là không gian để các nghệ sĩ, nhà sáng tạo nội dung và người dùng có thể kết nối, chia sẻ và kiếm tiền từ tác phẩm số của mình.

## 🌟 Tính năng nổi bật

### Khám phá và Giao dịch
- Dễ dàng tìm kiếm và lọc NFT theo nhiều tiêu chí
- Theo dõi xu hướng thị trường và NFT thịnh hành
- Hệ thống đấu giá minh bạch và công bằng
- Giao dịch P2P an toàn với smart contract

### Sáng tạo và Quản lý
- Công cụ mint NFT đơn giản và trực quan
- Tạo và quản lý bộ sưu tập cá nhân
- Tùy chỉnh metadata và thuộc tính NFT
- Theo dõi lịch sử giao dịch chi tiết

### Tương tác Cộng đồng
- Hệ thống đánh giá và review người dùng
- Diễn đàn thảo luận sôi động
- Tính năng theo dõi nghệ sĩ yêu thích
- Thông báo realtime về giao dịch và sự kiện

### Bảo mật và Tiện ích
- Tích hợp đa dạng ví điện tử
- Hệ thống xác thực hai lớp
- Backup và khôi phục tài khoản an toàn
- Hỗ trợ đa ngôn ngữ và đa nền tảng

## Thành viên nhóm 2:

1. Đào Xuân Huy - 21520913
2. Trần Thanh Hiền - 21520230
3. Ngô Trung Quân - 21521326

## Hướng dẫn cài đặt và chạy ứng dụng

### Cài đặt Mobile App (Flutter)

#### Yêu cầu hệ thống:

- JDK17
- Flutter 3.24.0
- Android Studio (cho phát triển Android)
- Metamask hoặc ví Web3 tương thích
- Git
- VSCode

#### Cài đặt môi trường phát triển:

1. **Clone repository:**
   ```bash
   git clone https://github.com/xhuy108/nft_marketplace_mobile
   ```

2. **Cài đặt dependencies:**
   ```bash
   flutter pub get
   ```
   
3. **Chạy ứng dụng:**
   ```bash
   Mở file chính của dự án, chọn Start Debugging
   ```

### Cài đặt Backend (Node.js + Ethereum)

#### Yêu cầu hệ thống:

- Solidity >= 0.8.0
- Hardhat (framework phát triển)
- Ganache (cho môi trường test local)
- MetaMask (ví Ethereum)
  
### Cấu trúc dự án
```
nft-marketplace-contracts/
├── artifacts/               # Compiled artifacts
├── cache/                  # Hardhat cache
├── contracts/              # Smart contracts
├── deploy/                 # Deploy scripts
├── deployment/             # Deployment config
├── node_modules/          # Dependencies
├── scripts/               # Utility scripts
├── test/                  # Test files
├── utils/                 # Helper utilities
├── .env                   # Environment variables
├── .gitignore            # Git ignore file
├── hardhat.config.js      # Hardhat configuration
├── helper-hardhat-config.js # Helper config
├── package.json          # Project config
├── package-lock.json     # Dependencies lock
├── README.md             # Documentation
└── test-connection.js    # Network test
```

#### Cài đặt:

1. **Clone repository:**
   ```bash
   git clone https://github.com/xhuy108/nft-marketplace-be.git
   ```

2. **Cài đặt dependencies:**
   ```bash
   npm install
   ```

3. **Cấu hình môi trường:**
   - Tạo file `.env` từ mẫu `.env.example`
   - Cập nhật các thông số:
     SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/1c542079fe524505b725a5dadbc8f1b9
     PRIVATE_KEY=b5044cbe77b9779921da655f1184af597ddb68caddc4fb01d6c20af47f5ef715
     ETHERSCAN_API_KEY=IHBQAN9S72F6KHS6W95U8RV7CC9TGMSA3T

4. **Compile smart contracts:**
   ```bash
   npx hardhat compile
   npx hardhat deploy --network <tên-mạng>
   ```

5. **Chạy test:**
   ```bash
   npx hardhat test
   ```

6. **Deploy smart contracts:**
   ```bash
   npx hardhat deploy --network localhost
   ```
   
## Lưu ý quan trọng

- Đảm bảo có đủ cryptocurrency trong ví để thực hiện các giao dịch
- Kiểm tra kết nối mạng blockchain phù hợp (testnet/mainnet)
- Backup private key và seed phrase của ví
- Kiểm tra phí gas trước khi thực hiện giao dịch

## Hỗ trợ và góp ý

Nếu bạn gặp vấn đề hoặc có đóng góp, vui lòng tạo issue trong repository hoặc liên hệ team phát triển.
