﻿--bai tap 1--
create database QLBH 
use QLBH 
create table KHACHHANG 
(
	MAKH char (4) primary key,
	HOTEN varchar(40),
	DCHI varchar(50),
	SODT varchar(20),
	NGSINH smalldatetime,
	NGDK smalldatetime,
	DOANHSO money,
)  
create table NHANVIEN
(
	MANV char (4) primary key,
	HOTEN varchar(40),
	SODT varchar(20),
	NGVL smalldatetime
)
create table SANPHAM
(
	MASP char (4) primary key,
	TENSP varchar(40),
	DVT varchar(20),
	NUOCSX varchar(40),
	GIA money
) 
create table HOADON
(
	SOHD int primary key,
	NGHD smalldatetime,
	MAKH char (4) foreign key references KHACHHANG(MAKH),
	MANV char (4) foreign key references NHANVIEN(MANV),
	TRIGIA money
)
create table CTHD 
(
	SOHD int foreign key references HOADON (SOHD) ,
	MASP char (4) foreign key references SANPHAM(MASP) ,
	SL int,
	constraint PK_CTHD primary key (SOHD, MASP)
)   
 -- câu 2 -- 
alter table SANPHAM add GHICHU varchar (20)
 -- câu 3 --
alter table KHACHHANG add LOAIKH tinyint
 -- câu 4 -- 
alter table SANPHAM alter column GHICHU varchar (100)
 -- câu 5 -- 
alter table SANPHAM drop column GHICHU
 -- câu 6 --
alter table KHACHHANG alter column LOAIKH varchar (20)
 -- câu 7 -- 
alter table SANPHAM add constraint CHECK_DVT check (DVT ='cay'OR DVT='cai'OR DVT='hop'OR DVT='quyen'OR DVT='chuc')
 -- câu 8 --
alter table SANPHAM add constraint CHECK_GIA check (GIA > 500) 
 -- câu 9 -- 
alter table CTHD add constraint CHECK_SL check (SL > 0) 
 -- câu 10 --
alter table KHACHHANG add constraint CHECK_NGDK check (NGDK > NGSINH)
-- câu 11 -- Ngày mua hàng (NGHD) của một khách hàng thành viên sẽ lớn hơn hoặc bằng ngày khách hàng đó đăng ký thành viên (NGDK).
CREATE TRIGGER trg_ins_hd ON HOADON
FOR INSERT
AS
BEGIN
	DECLARE @NgayHD smalldatetime, @MaKH char(4), @NgayDK smalldatetime
	SELECT @NgayHD = NGHD, @MaKH = MAKH
	FROM INSERTED
	SELECT @NgayDK = NGDK
	FROM KHACHHANG
	WHERE MAKH = @MaKH
	IF(@NgayHD < @NgayDK)
	BEGIN
		PRINT 'LOI: NGAY HOA DON KHONG HOP LE!'
		ROLLBACK TRANSACTION
	END
	ELSE
	BEGIN
		PRINT 'THEM MOI MOT HOA DON THANH CONG!'
	END
END
-- câu 12-- Ngày bán hàng (NGHD) của một nhân viên phải lớn hơn hoặc bằng ngày nhân viên đó vào làm
 CREATE TRIGGER nghd_ngvl_nv ON NHANVIEN
FOR UPDATE
AS
BEGIN 
	DECLARE @NGVL smalldatetime, @NGHD smalldatetime
	SELECT @NGVL = NGVL
	FROM  INSERTED
	IF(@NGVL > ANY (SELECT NGHD
		FROM  HOADON A, INSERTED I
		WHERE A.MANV = I.MANV))
	BEGIN
		PRINT 'LOI: NGAY VAO LAM PHAI NHO HON NGAY HOA DON!'
		ROLLBACK TRANSACTION
	END
	ELSE 
	BEGIN 
		PRINT' THANH CONG'
	END
END
-- CÂU 13 -- Mỗi một hóa đơn phải có ít nhất một chi tiết hóa đơn.
CREATE TRIGGER cthd_HD ON CTHD
FOR DELETE,UPDATE
AS
BEGIN
	DECLARE @SL  int, @SOHD int
	SELECT @SL = COUNT(A.SOHD), @SOHD = D.SOHD
	FROM  DELETED D,CTHD A
	WHERE A.SOHD = D.SOHD
	GROUP BY  D.SOHD
	IF(@SL < 1)
		BEGIN
			DELETE FROM HOADON
			WHERE  SOHD = @SOHD
			PRINT 'DA XOA CTHD CUOI CUNG CUA HOADON TREN'
		END 
END
-- CÂU 14 -- Trị giá của một hóa đơn là tổng thành tiền (số lượng*đơn giá) của các chi tiết thuộc hóa đơn đó.
CREATE TRIGGER update_cthd ON CTHD
FOR UPDATE
AS
BEGIN
	DECLARE  @SL_CU int, @SL_MOI int, @GIA_CU money, @GIA_MOI money, @SOHD_CU int, @SOHD_MOI int
	SELECT @GIA_CU = GIA, @SL_CU=SL, @SOHD_CU = SOHD
	FROM  DELETED A, SANPHAM B
	WHERE A.MASP = B.MASP
	SELECT @GIA_MOI = GIA,@SL_MOI = SL,@SOHD_MOI = SOHD
	FROM  INSERTED A, SANPHAM B
	WHERE A.MASP = B.MASP
	IF(@SOHD_CU = @SOHD_MOI)
		BEGIN
			UPDATE HOADON
			SET  TRIGIA = TRIGIA + @SL_MOI * @GIA_MOI - @SL_CU * @GIA_CU
			WHERE SOHD = @SOHD_CU
		END
	ELSE
		BEGIN
			UPDATE HOADON
			SET  TRIGIA = TRIGIA - @SL_CU * @GIA_CU
			WHERE SOHD = @SOHD_CU
			UPDATE HOADON
			SET  TRIGIA = TRIGIA + @SL_MOI * @GIA_MOI
			WHERE SOHD = @SOHD_MOI
		 END
	PRINT'DA UPDATE 1 CTHD VA UPDATE LAI TRIGIA CUA HOADON TUONG UNG'
END
-- câu 15-- Doanh số của một khách hàng là tổng trị giá các hóa đơn mà khách hàng thành viên đó đã mua.
CREATE TRIGGER update_hoadon ON HOADON
FOR UPDATE
AS
BEGIN
	DECLARE @TRIGIA_CU money, @TRIGIA_MOI money, @MAKH  char(4)
	SELECT @MAKH = MAKH, @TRIGIA_MOI = TRIGIA
	FROM  INSERTED
	SELECT @MAKH = MAKH, @TRIGIA_CU = TRIGIA
	FROM  DELETED
	UPDATE KHACHHANG
	SET  DOANHSO = DOANHSO + @TRIGIA_MOI - @TRIGIA_CU
	WHERE MAKH = @MAKH
	PRINT 'DA UPDATE 1 HOADON VA UPDATE LAI DOANHSO CUA KHACH HANG CO SOHD TREN'
END
 -- Chương 2 -- 
 -- câu 1 -- 

SET DATEFORMAT DMY

INSERT INTO NHANVIEN(MANV,HOTEN,SODT,NGVL) VALUES ('NV01','Nguyen Nhu Nhut','0927345678','13/4/2006')
INSERT INTO NHANVIEN(MANV,HOTEN,SODT,NGVL) VALUES ('NV02','Le Thi Phi Yen','0987567390','21/4/2006')
INSERT INTO NHANVIEN(MANV,HOTEN,SODT,NGVL) VALUES ('NV03','Nguyen Van B','0997047382','27/4/2006')
INSERT INTO NHANVIEN(MANV,HOTEN,SODT,NGVL) VALUES ('NV04','Ngo Thanh Tuan','0913758498','24/6/2006')
INSERT INTO NHANVIEN(MANV,HOTEN,SODT,NGVL) VALUES ('NV05','Nguyen Thi Truc Thanh','0918590387','20/7/2006')

INSERT INTO KHACHHANG(MAKH,HOTEN,DCHI,SODT,NGSINH,DOANHSO,NGDK) VALUES ('KH01','Nguyen Van A','731 Tran Hung Dao, Q5, TpHCM','08823451','22/10/1960','13,060,000','22/07/2006')
INSERT INTO KHACHHANG(MAKH,HOTEN,DCHI,SODT,NGSINH,DOANHSO,NGDK) VALUES ('KH02','Tran Ngoc Han','23/5 Nguyen Trai, Q5, TpHCM','0908256478','3/4/1974','280,000','30/07/2006')
INSERT INTO KHACHHANG(MAKH,HOTEN,DCHI,SODT,NGSINH,DOANHSO,NGDK) VALUES ('KH03','Tran Ngoc Linh','45 Nguyen Canh Chan, Q1, TpHCM','0938776266','12/6/1980','3,860,000','05/08/2006')
INSERT INTO KHACHHANG(MAKH,HOTEN,DCHI,SODT,NGSINH,DOANHSO,NGDK) VALUES ('KH04','Tran Minh Long','50/34 Le Dai Hanh, Q10, TpHCM','0917325476','9/3/1965','250,000','02/10/2006')
INSERT INTO KHACHHANG(MAKH,HOTEN,DCHI,SODT,NGSINH,DOANHSO,NGDK) VALUES ('KH05','Le Nhat Minh','34 Truong Dinh, Q3, TpHCM','08246108','10/3/1950','21,000','28/10/2006')
INSERT INTO KHACHHANG(MAKH,HOTEN,DCHI,SODT,NGSINH,DOANHSO,NGDK) VALUES ('KH06','Le Hoai Thuong','227 Nguyen Van Cu, Q5, TpHCM','08631738','31/12/1981','915,000','24/11/2006')
INSERT INTO KHACHHANG(MAKH,HOTEN,DCHI,SODT,NGSINH,DOANHSO,NGDK) VALUES ('KH07','Nguyen Van Tam','32/3 Tran Binh Trong, Q5, TpHCM','0916783565','6/4/1971','12,500','01/12/2006')
INSERT INTO KHACHHANG(MAKH,HOTEN,DCHI,SODT,NGSINH,DOANHSO,NGDK) VALUES ('KH08','Phan Thi Thanh','45/2 An Duong Vuong, Q5, TpHCM','0938435756','10/1/1971','365,000','13/12/2006')
INSERT INTO KHACHHANG(MAKH,HOTEN,DCHI,SODT,NGSINH,DOANHSO,NGDK) VALUES ('KH09','Le Ha Vinh','873 Le Hong Phong, Q5, TpHCM','08654763','3/9/1979','70,000','14/01/2007')
INSERT INTO KHACHHANG(MAKH,HOTEN,DCHI,SODT,NGSINH,DOANHSO,NGDK) VALUES ('KH10','Ha Duy Lap','34/34B Nguyen Trai, Q1, TpHCM','008768904','2/5/1983','67,500','16/01/2007')

INSERT INTO SANPHAM(MASP,TENSP,DVT,NUOCSX,GIA) VALUES ('BC01','But chi','cay','Singapore','3,000')
INSERT INTO SANPHAM(MASP,TENSP,DVT,NUOCSX,GIA) VALUES ('BC02','But chi','cay','Singapore','5,000')
INSERT INTO SANPHAM(MASP,TENSP,DVT,NUOCSX,GIA) VALUES ('BC03','But chi','cay','Viet Nam','3,500')
INSERT INTO SANPHAM(MASP,TENSP,DVT,NUOCSX,GIA) VALUES ('BC04','But chi','hop','Viet Nam','30,000')
INSERT INTO SANPHAM(MASP,TENSP,DVT,NUOCSX,GIA) VALUES ('BB01','But bi','cay','Viet Nam','5,000')
INSERT INTO SANPHAM(MASP,TENSP,DVT,NUOCSX,GIA) VALUES ('BB02','But bi','cay','Trung Quoc','7,000')
INSERT INTO SANPHAM(MASP,TENSP,DVT,NUOCSX,GIA) VALUES ('BB03','But bi','hop','Thai Lan','100,000')
INSERT INTO SANPHAM(MASP,TENSP,DVT,NUOCSX,GIA) VALUES ('TV01','Tap 100 giay mong','quyen','Trung Quoc','2,500')
INSERT INTO SANPHAM(MASP,TENSP,DVT,NUOCSX,GIA) VALUES ('TV02','Tap 200 giay mong','quyen','Trung Quoc','4,500')
INSERT INTO SANPHAM(MASP,TENSP,DVT,NUOCSX,GIA) VALUES ('TV03','Tap 100 giay tot','quyen','Viet Nam','3,000')
INSERT INTO SANPHAM(MASP,TENSP,DVT,NUOCSX,GIA) VALUES ('TV04','Tap 200 giay tot','quyen','Viet Nam','5,500')
INSERT INTO SANPHAM(MASP,TENSP,DVT,NUOCSX,GIA) VALUES ('TV05','Tap 100 trang','chuc','Viet Nam','23,000')
INSERT INTO SANPHAM(MASP,TENSP,DVT,NUOCSX,GIA) VALUES ('TV06','Tap 200 trang','chuc','Viet Nam','53,000')
INSERT INTO SANPHAM(MASP,TENSP,DVT,NUOCSX,GIA) VALUES ('TV07','Tap 100 trang','chuc','Trung Quoc','34,000')
INSERT INTO SANPHAM(MASP,TENSP,DVT,NUOCSX,GIA) VALUES ('ST01','So tay 500 trang','quyen','Trung Quoc','40,000')
INSERT INTO SANPHAM(MASP,TENSP,DVT,NUOCSX,GIA) VALUES ('ST02','So tay loai 1','quyen','Viet Nam','55,000')
INSERT INTO SANPHAM(MASP,TENSP,DVT,NUOCSX,GIA) VALUES ('ST03','So tay loai 2','quyen','Viet Nam','51,000')
INSERT INTO SANPHAM(MASP,TENSP,DVT,NUOCSX,GIA) VALUES ('ST04','So tay','quyen','Thai Lan','55,000')
INSERT INTO SANPHAM(MASP,TENSP,DVT,NUOCSX,GIA) VALUES ('ST05','So tay mong','quyen','Thai Lan','20,000')
INSERT INTO SANPHAM(MASP,TENSP,DVT,NUOCSX,GIA) VALUES ('ST06','Phan viet bang','hop','Viet Nam','5,000')
INSERT INTO SANPHAM(MASP,TENSP,DVT,NUOCSX,GIA) VALUES ('ST07','Phan khong bui','hop','Viet Nam','7,000')
INSERT INTO SANPHAM(MASP,TENSP,DVT,NUOCSX,GIA) VALUES ('ST08','Bong bang','cai','Viet Nam','1,000')
INSERT INTO SANPHAM(MASP,TENSP,DVT,NUOCSX,GIA) VALUES ('ST09','But long','cay','Viet Nam','5,000')
INSERT INTO SANPHAM(MASP,TENSP,DVT,NUOCSX,GIA) VALUES ('ST10','But long','cay','Trung Quoc','7,000')

INSERT INTO HOADON(SOHD,NGHD,MAKH,MANV,TRIGIA) VALUES ('1001','23/07/2006','KH01','NV01','320,000')
INSERT INTO HOADON(SOHD,NGHD,MAKH,MANV,TRIGIA) VALUES ('1002','12/08/2006','KH01','NV02','840,000')
INSERT INTO HOADON(SOHD,NGHD,MAKH,MANV,TRIGIA) VALUES ('1003','23/08/2006','KH02','NV01','100,000')
INSERT INTO HOADON(SOHD,NGHD,MAKH,MANV,TRIGIA) VALUES ('1004','01/09/2006','KH02','NV01','180,000')
INSERT INTO HOADON(SOHD,NGHD,MAKH,MANV,TRIGIA) VALUES ('1005','20/10/2006','KH01','NV02','3,800,000')
INSERT INTO HOADON(SOHD,NGHD,MAKH,MANV,TRIGIA) VALUES ('1006','16/10/2006','KH01','NV03','2,430,000')
INSERT INTO HOADON(SOHD,NGHD,MAKH,MANV,TRIGIA) VALUES ('1007','28/10/2006','KH03','NV03','510,000')
INSERT INTO HOADON(SOHD,NGHD,MAKH,MANV,TRIGIA) VALUES ('1008','28/10/2006','KH01','NV03','440,000')
INSERT INTO HOADON(SOHD,NGHD,MAKH,MANV,TRIGIA) VALUES ('1009','28/10/2006','KH03','NV04','200,000')
INSERT INTO HOADON(SOHD,NGHD,MAKH,MANV,TRIGIA) VALUES ('1010','01/11/2006','KH01','NV01','5,200,000')
INSERT INTO HOADON(SOHD,NGHD,MAKH,MANV,TRIGIA) VALUES ('1011','04/11/2006','KH04','NV03','250,000')
INSERT INTO HOADON(SOHD,NGHD,MAKH,MANV,TRIGIA) VALUES ('1012','30/11/2006','KH05','NV03','21,000')
INSERT INTO HOADON(SOHD,NGHD,MAKH,MANV,TRIGIA) VALUES ('1013','12/12/2006','KH06','NV01','5,000')
INSERT INTO HOADON(SOHD,NGHD,MAKH,MANV,TRIGIA) VALUES ('1014','31/12/2006','KH03','NV02','3,150,000')
INSERT INTO HOADON(SOHD,NGHD,MAKH,MANV,TRIGIA) VALUES ('1015','01/01/2007','KH06','NV01','910,000')
INSERT INTO HOADON(SOHD,NGHD,MAKH,MANV,TRIGIA) VALUES ('1016','01/01/2007','KH07','NV02','12,500')
INSERT INTO HOADON(SOHD,NGHD,MAKH,MANV,TRIGIA) VALUES ('1017','02/01/2007','KH08','NV03','35,000')
INSERT INTO HOADON(SOHD,NGHD,MAKH,MANV,TRIGIA) VALUES ('1018','13/01/2007','KH08','NV03','330,000')
INSERT INTO HOADON(SOHD,NGHD,MAKH,MANV,TRIGIA) VALUES ('1019','13/01/2007','KH01','NV03','30,000')
INSERT INTO HOADON(SOHD,NGHD,MAKH,MANV,TRIGIA) VALUES ('1020','14/01/2007','KH09','NV04','70,000')
INSERT INTO HOADON(SOHD,NGHD,MAKH,MANV,TRIGIA) VALUES ('1021','16/01/2007','KH10','NV03','67,500')
INSERT INTO HOADON(SOHD,NGHD,MANV,TRIGIA) VALUES ('1022','16/01/2007','NV03','7,000')
INSERT INTO HOADON(SOHD,NGHD,MANV,TRIGIA) VALUES ('1023','17/01/2007','NV01','330,000')

INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1001','TV02','10')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1001','ST01','5')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1001','BC01','5')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1001','BC02','10')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1001','ST08','10')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1002','BC04','20')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1002','BB01','20')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1002','BB02','20')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1003','BB03','10')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1004','TV01','20')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1004','TV02','10')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1004','TV03','10')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1004','TV04','10')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1005','TV05','50')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1005','TV06','50')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1006','TV07','20')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1006','ST01','30')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1006','ST02','10')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1007','ST03','10')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1008','ST04','8')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1009','ST05','10')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1010','TV07','50')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1010','ST07','50')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1010','ST08','100')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1010','ST04','50')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1010','TV03','100')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1011','ST06','50')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1012','ST07','3')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1013','ST08','5')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1014','BC02','80')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1014','BB02','100')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1014','BC04','60')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1014','BB01','50')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1015','BB02','30')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1015','BB03','7')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1016','TV01','5')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1017','TV02','1')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1017','TV03','1')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1017','TV04','5')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1018','ST04','6')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1019','ST05','1')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1019','ST06','2')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1020','ST07','10')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1021','ST08','5')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1021','TV01','7')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1021','TV02','10')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1022','ST07','1')
INSERT INTO CTHD(SOHD,MASP,SL) VALUES ('1023','ST04','6')


-- CÂU 2 -- 

create table SANPHAM1
(
	MASP char (4) primary key,
	TENSP varchar(40),
	DVT varchar(20),
	NUOCSX varchar(40),
	GIA money
) 

create table KHACHHANG1 
(
	MAKH char (4) primary key,
	HOTEN varchar(40),
	DCHI varchar(50),
	SODT varchar(20),
	NGSINH smalldatetime,
	NGDK smalldatetime,
	DOANHSO money,
)  

INSERT INTO SANPHAM1 SELECT *FROM SANPHAM;
SELECT *FROM SANPHAM1; 
alter table KHACHHANG1 ADD LOAIKH varchar (20);
INSERT INTO KHACHHANG1 SELECT *FROM KHACHHANG;
SELECT *FROM KHACHHANG1;

-- CÂU 3 Cập nhật giá tăng 5% đối với những sản phẩm do “Thai Lan” sản xuất (cho quan hệ SANPHAM1)-- 

UPDATE SANPHAM1 SET GIA = GIA*1.05 WHERE NUOCSX = 'Thai Lan';
SELECT *FROM SANPHAM1;

-- câu 4 Cập nhật giá giảm 5% đối với những sản phẩm do “Trung Quoc” sản xuất có giá từ 10.000 trở xuống (cho quan hệ SANPHAM1)-- 
UPDATE SANPHAM1 SET GIA = GIA*0.95 WHERE NUOCSX = 'Trung Quoc' AND GIA <= 10000; 
SELECT *FROM SANPHAM1;

-- câu 5 Cập nhật giá trị LOAIKH là “Vip” đối với những khách hàng đăng ký thành viên trước ngày 1/1/2007 có doanh số từ 10.000.000 trở lên hoặc khách hàng đăng ký thành viên từ 1/1/2007 trở về sau có doanh số từ 2.000.000 trở lên (cho quan hệ KHACHHANG1).
 
UPDATE KHACHHANG1 SET LOAIKH ='Vip' WHERE (NGDK < '01/01/2007' AND DOANHSO >= 10000000) OR ( NGDK >= '01/01/2007' AND DOANHSO > 20000000 );
SELECT *FROM KHACHHANG1; 


-- Chương 3-- 
-- câu 1-- 
SELECT MASP, TENSP FROM SANPHAM WHERE NUOCSX='Trung Quoc'
--câu 2-- 
SELECT MASP, TENSP FROM SANPHAM WHERE DVT IN('cay', 'quyen')
-- câu 3-- 
SELECT MASP, TENSP FROM SANPHAM WHERE MASP LIKE 'B%01'
-- câu 4-- 
SELECT MASP, TENSP FROM SANPHAM  WHERE GIA >=30000 AND GIA <=40000 AND NUOCSX ='Trung Quoc'
-- câu 5 -- 
SELECT MASP, TENSP FROM SANPHAM  WHERE GIA >=30000 AND GIA <=40000 AND NUOCSX IN('Trung Quoc','Thai Lan')
-- câu 6 -- 
SET DATEFORMAT DMY
SELECT SOHD, TRIGIA FROM HOADON WHERE NGHD IN('1/1/2007','2/1/2007')
-- câu 7 -- 
SELECT SOHD, TRIGIA FROM HOADON WHERE MONTH(NGHD) = 1 AND YEAR (NGHD) = 2007  ORDER BY NGHD ASC, TRIGIA DESC
-- câu 8 -- 
SELECT KHACHHANG1.MAKH, HOTEN FROM KHACHHANG1 INNER JOIN HOADON ON KHACHHANG1.MAKH = HOADON.MAKH WHERE NGHD = '1/1/2007'
-- câu 9 -- 
SELECT SOHD, TRIGIA FROM HOADON INNER JOIN KHACHHANG ON KHACHHANG.MAKH = HOADON.MAKH WHERE NGHD = '28/10/2006' AND HOTEN = 'Nguyen Van B'
-- câu 10 -- 
SELECT SANPHAM.MASP, TENSP
FROM SANPHAM INNER JOIN CTHD ON SANPHAM.MASP = CTHD.MASP
	INNER JOIN HOADON ON CTHD.SOHD = HOADON.SOHD
	INNER JOIN  KHACHHANG ON HOADON.MAKH = KHACHHANG.MAKH
WHERE HOTEN = 'Nguyen Van A' AND MONTH(NGHD) = 10 AND YEAR(NGHD) = 2006
-- câu 11-- 
SELECT DISTINCT SOHD FROM CTHD WHERE MASP IN ('BB01' ,'BB02')
-- câu 12-- 
SELECT DISTINCT SOHD FROM CTHD WHERE MASP IN ('BB01' ,'BB02') AND (SL BETWEEN 10 AND 20)
-- câu 13 -- 
SELECT DISTINCT SOHD FROM CTHD WHERE MASP = 'BB01' AND (SL BETWEEN 10 AND 20)
INTERSECT -- PHÉP GIAO, DK: PHẢI KHẢ HỢP
SELECT DISTINCT SOHD FROM CTHD WHERE MASP = 'BB02' AND (SL BETWEEN 10 AND 20)
-- câu 14-- 
SELECT MASP, TENSP  FROM SANPHAM  WHERE NUOCSX = 'Trung Quoc'
UNION
SELECT SANPHAM.MASP, TENSP
FROM SANPHAM INNER JOIN CTHD ON CTHD.MASP = SANPHAM.MASP
INNER JOIN HOADON ON HOADON.SOHD = CTHD.SOHD
WHERE NGHD = '01/01/2007'

--15.	In ra danh sách các sản phẩm (MASP,TENSP) không bán được.
SELECT MASP, TENSP
FROM SANPHAM 
WHERE NOT EXISTS(SELECT * FROM SANPHAM S2 , CTHD WHERE S2.MASP = CTHD.MASP AND S2.MASP = SANPHAM.MASP)
--16.	In ra danh sách các sản phẩm (MASP,TENSP) không bán được trong năm 2006.
SELECT MASP, TENSP
FROM SANPHAM
WHERE NOT EXISTS( SELECT * FROM CTHD,HOADON WHERE YEAR(NGHD) = 2006 AND SANPHAM.MASP=CTHD.MASP AND HOADON.SOHD=CTHD.SOHD)

--17.	In ra danh sách các sản phẩm (MASP,TENSP) do “Trung Quoc” sản xuất không bán được trong năm 2006.
SELECT MASP, TENSP
FROM SANPHAM
WHERE NUOCSX = 'Trung Quoc'
EXCEPT
SELECT SANPHAM.MASP, TENSP
FROM SANPHAM, CTHD, HOADON WHERE  SANPHAM.MASP = CTHD.MASP  AND CTHD.SOHD = HOADON.SOHD AND YEAR(NGHD) = 2006
--18.	Tìm số hóa đơn đã mua tất cả các sản phẩm do Singapore sản xuất.
SELECT SOHD 
FROM HOADON 
WHERE NOT EXISTS(SELECT *FROM SANPHAM WHERE NUOCSX = 'SINGAPORE'AND NOT EXISTS(SELECT * 
FROM CTHD 
WHERE HOADON.SOHD = CTHD.SOHD AND CTHD.MASP = SANPHAM.MASP))

--19.	Tìm số hóa đơn trong năm 2006 đã mua ít nhất tất cả các sản phẩm do Singapore sản xuất.
SELECT SOHD 
FROM HOADON 
WHERE YEAR(NGHD) = 2006 AND NOT EXISTS(SELECT * FROM SANPHAM WHERE NUOCSX = 'SINGAPORE' 
										AND NOT EXISTS(SELECT * FROM CTHD WHERE CTHD.SOHD = HOADON.SOHD AND CTHD.MASP = SANPHAM.MASP))
--20.	Có bao nhiêu hóa đơn không phải của khách hàng đăng ký thành viên mua?
SELECT COUNT(SOHD)
FROM HOADON 
WHERE NOT EXISTS (SELECT MAKH FROM KHACHHANG WHERE HOADON.MAKH=KHACHHANG.MAKH)

--21.	Có bao nhiêu sản phẩm khác nhau được bán ra trong năm 2006.
SELECT COUNT(DISTINCT MASP) SOSANPHAM
FROM CTHD, HOADON
WHERE HOADON.SOHD = CTHD.SOHD AND YEAR(NGHD) = 2006
--22.	Cho biết trị giá hóa đơn cao nhất, thấp nhất là bao nhiêu ?
SELECT MAX(TRIGIA) AS MAX, MIN(TRIGIA) AS MIN
FROM HOADON
--23.	Trị giá trung bình của tất cả các hóa đơn được bán ra trong năm 2006 là bao nhiêu?
SELECT AVG(TRIGIA) TB
FROM HOADON
WHERE YEAR(NGHD) = 2006
--24.	Tính doanh thu bán hàng trong năm 2006.
SELECT SUM(TRIGIA) AS DOANHTHU
FROM HOADON
WHERE YEAR(NGHD) = 2006
--25.	Tìm số hóa đơn có trị giá cao nhất trong năm 2006.
SELECT SOHD
FROM HOADON
WHERE YEAR(NGHD)='2006' AND TRIGIA = (SELECT MAX(TRIGIA) FROM HOADON)
--26.	Tìm họ tên khách hàng đã mua hóa đơn có trị giá cao nhất trong năm 2006.
SELECT HOTEN
FROM KHACHHANG, HOADON 
WHERE  YEAR(NGHD)='2006' AND KHACHHANG.MAKH = HOADON.MAKH AND SOHD = (SELECT SOHD FROM HOADON WHERE TRIGIA = (SELECT MAX(TRIGIA) FROM HOADON))
			
--27.	In ra danh sách 3 khách hàng (MAKH, HOTEN) có doanh số cao nhất.
SELECT TOP 3 MAKH, HOTEN
FROM KHACHHANG
ORDER BY DOANHSO DESC
--28.	In ra danh sách các sản phẩm (MASP, TENSP) có giá bán bằng 1 trong 3 mức giá cao nhất.
SELECT MASP, TENSP FROM SANPHAM WHERE GIA in (SELECT DISTINCT TOP 3 GIA  FROM SANPHAM  ORDER BY GIA DESC)
--29.	In ra danh sách các sản phẩm (MASP, TENSP) do “Thai Lan” sản xuất có giá bằng 1 trong 3 mức giá cao nhất (của tất cả các sản phẩm).
SELECT MASP, TENSP FROM SANPHAM WHERE NUOCSX = 'THAI LAN' 
										AND GIA IN (SELECT DISTINCT TOP 3 GIA FROM SANPHAM ORDER BY GIA DESC)
--30.	In ra danh sách các sản phẩm (MASP, TENSP) do “Trung Quoc” sản xuất có giá bằng 1 trong 3 mức giá cao nhất (của sản phẩm do “Trung Quoc” sản xuất).
SELECT MASP, TENSP FROM SANPHAM WHERE NUOCSX = 'TRUNG QUOC'
										AND GIA IN (SELECT DISTINCT TOP 3 GIA FROM SANPHAM WHERE NUOCSX = 'TRUNG QUOC' ORDER BY GIA DESC)


-- bai tap 2-- 

create database QUANLYGIAOVU
use QUANLYGIAOVU  

CREATE TABLE KHOA 
(
	MAKHOA varchar(4) PRIMARY KEY,
	TENKHOA varchar(40),
	NGTLAP SMALLDATETIME,
	TRGKHOA CHAR(4)
)
CREATE TABLE MONHOC 
(
	MAMH VARCHAR(10) PRIMARY KEY,
	TENMH VARCHAR(40),
	TCLT TINYINT,
	TCTH TINYINT,
	MAKHOA VARCHAR(4) foreign key references KHOA( MAKHOA)
)
CREATE TABLE DIEUKIEN
(
	MAMH VARCHAR(10) NOT NULL foreign key references MONHOC (MAMH),
	MAMH_TRUOC VARCHAR(10) NOT NULL foreign key references MONHOC (MAMH),
	primary key (MAMH, MAMH_TRUOC)
)
CREATE TABLE GIAOVIEN
(
	MAGV CHAR(4) PRIMARY KEY,
	HOTEN VARCHAR(40),
	HOCVI VARCHAR(10),
	HOCHAM VARCHAR(10),
	GIOITINH VARCHAR(3),
	NGSINH SMALLDATETIME,
	NGVL SMALLDATETIME,
	HESO NUMERIC (4,2),
	MUCLUONG MONEY, 
	MAKHOA VARCHAR(4) foreign key references KHOA (MAKHOA),
)

CREATE TABLE LOP
(
	MALOP CHAR(3) PRIMARY KEY,
	TENLOP VARCHAR(40),
	TRGLOP CHAR(5),
	SISO TINYINT,
	MAGVCN CHAR(4)
)

CREATE TABLE HOCVIEN(
	MAHV CHAR(5) PRIMARY KEY,
	HO VARCHAR(40),
	TEN VARCHAR(10),
	NGSINH SMALLDATETIME,
	GIOITINH VARCHAR(3),
	NOISINH VARCHAR(40),
	MALOP CHAR(3) foreign key references LOP(MALOP)
)

CREATE TABLE GIANGDAY
(
	MALOP CHAR(3) NOT NULL foreign key references LOP(MALOP),
	MAMH VARCHAR(10) NOT NULL foreign key references MONHOC(MAMH),
	MAGV CHAR(4) foreign key references GIAOVIEN (MAGV),
	HOCKY TINYINT,
	NAM SMALLINT,
	TUNGAY SMALLDATETIME, 
	DENNGAY SMALLDATETIME,
	PRIMARY KEY(MALOP, MAMH)
)

CREATE TABLE KETQUATHI
(
	MAHV CHAR(5) NOT NULL foreign key references HOCVIEN (MAHV),
	MAMH VARCHAR(10) NOT NULL foreign key references MONHOC (MAMH),
	LANTHI TINYINT NOT NULL,
	NGTHI SMALLDATETIME,
	DIEM NUMERIC(4,2),
	KQUA VARCHAR(10)
	PRIMARY KEY(MAHV, MAMH, LANTHI)
)
ALTER TABLE HOCVIEN ADD GHICHU VARCHAR(50)

ALTER TABLE HOCVIEN  ADD DIEMTB NUMERIC(4,2)

ALTER TABLE HOCVIEN ADD XEPLOAI CHAR(10)

-- CÂU 3 -- 
alter table HOCVIEN add constraint CHECK_HV CHECK (GIOITINH IN ('Nam', 'Nu'))
alter table GIAOVIEN add constraint CHECK_GV CHECK (GIOITINH IN ('Nam', 'Nu'))
-- câu 4 -- 
alter table KETQUATHI add constraint CHECK_KQT CHECK ( DIEM >= 0 AND DIEM <=10 ) 
-- Câu 5 -- 
alter table KETQUATHI add constraint CHECK_D_KD CHECK ((KQUA ='DAT' AND DIEM BETWEEN 5 AND 10) or ( KQUA = 'KHONG DAT' AND DIEM >= 0 AND DIEM <5 ))
-- câu 6 -- 
alter table KETQUATHI add constraint CHECK_THI CHECK ( LANTHI >0 AND LANTHI <= 3 )
-- CÂU 7 --
alter table GIANGDAY add constraint CHECK_HK CHECK (HOCKY BETWEEN 1 AND 3 ) 
-- CÂU 8 -- 
alter table GIAOVIEN add constraint CHECK_GVI CHECK ( HOCVI	IN ( 'CN', 'KS', 'ThS', 'TS', 'PTS' ) )	
-- câu 11 -- 
alter table HOCVIEN add constraint CHECK_TUOIHV CHECK (YEAR(GETDATE()) - YEAR(NGSINH) >= 18) 
-- câu 12 -- 
alter table GIANGDAY add constraint CHECK_NG CHECK ( TUNGAY < DENNGAY ) 
-- câu 13 -- 
alter table GIAOVIEN add constraint CHECK_TUOIGV CHECK ( YEAR(NGVL) - YEAR(NGSINH) >=22 ) 
-- câu 14 -- 
alter table MONHOC add constraint CHECK_MH CHECK ( ABS(TCLT - TCTH) <= 3)  

-- CHƯƠNG 2 -- 
-- CÂU 1: Tăng hệ số lương thêm 0.2 cho những giáo viên là trưởng khoa.-- 

update GIAOVIEN 
set HESO = 0.2 + HESO
where MAGV in ( select TRGKHOA FROM KHOA ) 
-- CÂU 2: Cập nhật giá trị điểm trung bình tất cả các môn học  (DIEMTB) của mỗi học viên (tất cả các môn học đều có hệ số 1 và nếu học viên thi một môn nhiều lần, chỉ lấy điểm của lần thi sau cùng).--
update HOCVIEN 
set DIEMTB = 
(	SELECT AVG(DIEM) 
	FROM KETQUATHI 
	WHERE LANTHI = ( SELECT MAX(LANTHI) FROM KETQUATHI WHERE MAHV = KETQUATHI.MAHV GROUP BY MAHV) 
	GROUP BY MAHV 
	HAVING MAHV = HOCVIEN.MAHV
)
-- CÂU 3: Cập nhật giá trị cho cột GHICHU là “Cam thi” đối với trường hợp: học viên có một môn bất kỳ thi lần thứ 3 dưới 5 điểm -- 
update HOCVIEN 
set GHICHU = 'Cam thi'
where MAHV IN 
(
	SELECT MAHV 
	FROM KETQUATHI 
	WHERE LANTHI =3 AND DIEM < 5 
)
-- CÂU 4 4.	Cập nhật giá trị cho cột XEPLOAI trong quan hệ HOCVIEN như sau: -- 
update HOCVIEN 
set XEPLOAI =
( 
	case 
		when DIEMTB >= 9 THEN 'XS'
		WHEN DIEMTB >= 8 AND DIEMTB <9 THEN 'G'
		WHEN DIEMTB >= 6.5 AND DIEMTB < 8 THEN 'K'
		WHEN DIEMTB >=5 AND DIEMTB <6.5 THEN 'TB'
		WHEN DIEMTB < 5 THEN 'Y'
	end 
)
