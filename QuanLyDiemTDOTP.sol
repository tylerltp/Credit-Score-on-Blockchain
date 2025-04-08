// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Thư viện tính điểm tín dụng
library CreditScoreLib {
    uint constant MAX_SCORE = 750;
    // (1) Tính điểm lịch sử thanh toán
    function tinhDiemLSTT(uint thanhToanDungHan) internal pure returns (uint) {
        require(thanhToanDungHan <= 12, "Khong hop le.");
        if (thanhToanDungHan > 10) {
            return (35 * MAX_SCORE) / 100;
        } else if (thanhToanDungHan == 10) {
            return (30 * MAX_SCORE) / 100;
        } else if (thanhToanDungHan == 9) {
            return (25 * MAX_SCORE) / 100;
        } else if (thanhToanDungHan == 8) {
            return (20 * MAX_SCORE) / 100;
        } else if (thanhToanDungHan == 7) {
            return (15 * MAX_SCORE) / 100;
        } else if (thanhToanDungHan == 6) {
            return (10 * MAX_SCORE) / 100;
        } else if (thanhToanDungHan == 5) {
            return (5 * MAX_SCORE) / 100;
        } else {
            return 0;
        }
    }
    // (2) Tính điểm lượng dư nợ
    function tinhDiemLuongDuNo(uint soTienNo) internal pure returns (uint) {
        if (soTienNo > 1000) {
            return 0;
        } else if (soTienNo > 800) {
            return (5 * MAX_SCORE) / 100;
        } else if (soTienNo > 600) {
            return (10 * MAX_SCORE) / 100;
        } else if (soTienNo > 400) {
            return (15 * MAX_SCORE) / 100;
        } else if (soTienNo > 200) {
            return (20 * MAX_SCORE) / 100;
        } else if (soTienNo > 100) {
            return (25 * MAX_SCORE) / 100;
        } else {
            return (30 * MAX_SCORE) / 100;
        }
    }
    // (3) Tính điểm độ dài lịch sử tín dụng
    function tinhDiemDoDaiLSTD(uint thoiGianMoTKTD) internal pure returns (uint) {
        if (thoiGianMoTKTD > 15) {
            return (15 * MAX_SCORE) / 100;
        } else if (thoiGianMoTKTD > 10) {
            return (10 * MAX_SCORE) / 100;
        } else if (thoiGianMoTKTD > 5) {
            return (5 * MAX_SCORE) / 100;
        } else {
            return 0;
        }
    }
    // (4) Tính điểm số lượng khoản vay
    function tinhDiemSoLuongKhoanVay(uint soLuongTDSoHuu) internal pure returns (uint) {
        if (soLuongTDSoHuu == 0) {
            return (10 * MAX_SCORE) / 100;
        } else if (soLuongTDSoHuu < 3) {
            return (5 * MAX_SCORE) / 100;
        } else {
            return 0;
        }
    }
    // (5) Tính điểm loại hình khoản vay
    function tinhDiemLoaiHinhKhoanVay(uint mucDichVay) internal pure returns (uint) {
        if (mucDichVay == 1) {
            return (10 * MAX_SCORE) / 100;
        } else if (mucDichVay == 2) {
            return (5 * MAX_SCORE) / 100;
        } else {
            return 0;
        }
    }
}

contract QuanLyDiemTinDung {
    address private cicAdmin;
    mapping(string => uint) private activeOTP;
    mapping(string => uint) private otpTimestamp;
    mapping(string => uint) private otpNonce;
    uint constant private OTP_VALIDITY_PERIOD = 5 minutes;

    constructor() {
        cicAdmin = msg.sender;
    }
    modifier onlyCICAdmin() {
        require(msg.sender == cicAdmin, "Only admin can perform this action.");
        _;
    }

    struct CIC {
        string canCuocCongDan;
        string ngayCap;
        string tenKhachHang;
        string phanLoaiCIC;
        string soDienThoai;
        bool hopLe;
    }
    mapping(string => CIC) private thongTinTD;

    event capNhatDiemTD(
        string indexed canCuocCongDan,
        string ngayCap,
        string tenKhachHang,
        string phanLoaiCIC,
        string soDienThoai
    );
    event guiOTP(string indexed canCuocCongDan, uint otp);

    using CreditScoreLib for uint;
    function tinhVaPhanLoaiTinDung(
        uint thanhToanDungHan,
        uint soTienNo,
        uint thoiGianMoTKTD,
        uint soLuongTDSoHuu,
        uint mucDichVay
    ) private pure returns (string memory phanLoaiTD) {
        uint diem1 = thanhToanDungHan.tinhDiemLSTT();
        uint diem2 = soTienNo.tinhDiemLuongDuNo();
        uint diem3 = thoiGianMoTKTD.tinhDiemDoDaiLSTD();
        uint diem4 = soLuongTDSoHuu.tinhDiemSoLuongKhoanVay();
        uint diem5 = mucDichVay.tinhDiemLoaiHinhKhoanVay();

        uint diemTinDung = diem1 + diem2 + diem3 + diem4 + diem5;

        if (diemTinDung >= 680) {
            return "CIC nhom 1";
        } else if (diemTinDung >= 570) {
            return "CIC nhom 2";
        } else if (diemTinDung >= 431) {
            return "CIC nhom 3";
        } else if (diemTinDung >= 322) {
            return "CIC nhom 4";
        } else {
            return "CIC nhom 5";
        }
    }
    function creditScoreCenter(
        string memory _canCuocCongDan,
        string memory _ngayCap,
        string memory _tenKhachHang,
        string memory _soDienThoai,
        uint thanhToanDungHan,
        uint soTienNo,
        uint thoiGianMoTKTD,
        uint soLuongTDSoHuu,
        uint mucDichVay
    ) public onlyCICAdmin {
        string memory phanLoaiCIC = tinhVaPhanLoaiTinDung(
            thanhToanDungHan,
            soTienNo,
            thoiGianMoTKTD,
            soLuongTDSoHuu,
            mucDichVay
        );
        thongTinTD[_canCuocCongDan] = CIC({
            canCuocCongDan: _canCuocCongDan,
            ngayCap: _ngayCap,
            tenKhachHang: _tenKhachHang,
            phanLoaiCIC: phanLoaiCIC,
            soDienThoai: _soDienThoai,
            hopLe: true
        });
        emit capNhatDiemTD(_canCuocCongDan, _ngayCap, _tenKhachHang, phanLoaiCIC, _soDienThoai);
    }
    function taoVaGuiOTP(string memory canCuocCongDan, string memory soDienThoai) 
        public returns (uint) {
        require(thongTinTD[canCuocCongDan].hopLe, "Thong tin khong hop le.");
        require(
            keccak256(abi.encodePacked(thongTinTD[canCuocCongDan].soDienThoai)) == 
            keccak256(abi.encodePacked(soDienThoai)), 
            "So dien thoai khong khop"
        );
        // Tăng nonce cho mỗi lần tạo OTP
        otpNonce[canCuocCongDan]++;
        // Tạo OTP mới 
        uint newOTP = uint(keccak256(abi.encodePacked(
            block.timestamp,
            msg.sender,
            otpNonce[canCuocCongDan],
            canCuocCongDan,
            block.prevrandao
        ))) % 900000 + 100000; 
        // Lưu OTP mới và thời gian tạo
        activeOTP[canCuocCongDan] = newOTP;
        otpTimestamp[canCuocCongDan] = block.timestamp;
        emit guiOTP(canCuocCongDan, newOTP);
        return newOTP;
    }
    function traCuuThongTinTD(string memory canCuocCongDan, uint otp) 
        public view returns (
            string memory _canCuocCongDan,
            string memory _ngayCap,
            string memory _tenKhachHang,
            string memory _phanLoaiCIC,
            string memory _soDienThoai,
            bool hopLe)
        {
            CIC memory thongTin = thongTinTD[canCuocCongDan];
            require(thongTin.hopLe, "Thong tin khong hop le");
            // Kiểm tra OTP có tồn tại và còn hiệu lực
            require(activeOTP[canCuocCongDan] == otp, "OTP khong hop le");
            require(block.timestamp - otpTimestamp[canCuocCongDan] <= OTP_VALIDITY_PERIOD, "OTP da het han");
            return (
                thongTin.canCuocCongDan,
                thongTin.ngayCap,
                thongTin.tenKhachHang,
                thongTin.phanLoaiCIC,
                thongTin.soDienThoai,
                thongTin.hopLe);
        }
}