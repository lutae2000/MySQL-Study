use sqldb;

-- 트리거 실습하기
-- 트리거는 방아쇠란 뜻이다.트리거는 어떤 특정한 테이블에 부착이 되어서
-- 부착되어진 테이블에서 삽입,수정,삭제의 작업이 일어나면 자동실행이 되는
-- 스토어드 프로그램의 부류이다.
-- IN, OUT등 매개변수를 사용할 수 없다.
drop table if exists testtbl;
create table testtbl(
	id int,
    txt varchar(10)    
);
insert into testtbl values (1, '애프터스쿨'),
						   (2, 'exid'),(3, 'ioi');
select *
  from testtbl;

-- 트리거 생성후 부착함
drop trigger if exists testtrigger;
delimiter //
create trigger testtrigger    -- 트리거명
	after delete              -- testtbl에서 데이터 삭제가 된 후 바로 실행
    on testtbl                -- testtbl에 부착시킴
    for each row              -- 각 행마다 다 적용시키겠다.
begin
	declare txt_singer varchar(10);	
	set txt_singer = old.txt;   -- old는 트리거가 작동할 때, 임시로 만들어지는 테이블이다.
    set @msg = concat('삭제된 가수이름 : ', txt_singer);
end //
delimiter ;

-- 삽입을 했는데 msg가 출력되지 아니한다.그 이유는 바로 트리거를 생성하고 
-- 부착한 내용이 바로 delete부분에만 적용이 되는 것 때문이다.
set @msg = '';
insert into testtbl values(4, '베이비복스');
select @msg;

-- 역시 수정부분에도 트리거를 부착을 시키지 않았으므로 아무런 출력결과가 나오지 않음
-- 을 알수가 있다.
set @msg = '';
update testtbl 
   set txt = '에이핑크'
where id = 3;
select @msg;

select *
  from testtbl;

-- 하지만, 삭제는 트리거를 부착시켰기에 아래와 같이 출력이 되는 것을 볼수가 있다.
delete from testtbl
 where id = 4;

select @msg;

-- 로그 데이터를 남기는 트리거를 만들어보자.
drop table buytbl;

-- 로그 데이터를 남기기 위해서 usertbl의 백업테이블인 backup_usertbl을 만들어보자
drop table if exists backup_usertbl;
create table backup_usertbl(
	userid char(8) not null primary key,
    username varchar(10) not null,
    birthyear int not null,
    addr char(2) not null,
    mobile1 char(3),
    mobile2 char(8),
    height smallint,
    mdate date,
    
    -- ------------------
    modtype char(2),  -- 변경된 작업을 명시하기 위해서 추가(수정이냐? 삭제냐?)
    moddate datetime,  -- 변경된 날짜를 저장
    moduser varchar(256)  -- 변경한 사용자 저장
);

-- 이제 usertbl에 수정시 자동실행되는 트리거를 생성하여 부착해보자
drop trigger if exists backupusertbl_updatetrg;
delimiter //
create trigger backupusertbl_updatetrg
	after update
    on usertbl
    for each row
begin
	-- 데이터를 update후 자동으로 실행되는 트리거의 내용이다.
	-- 여기서 old는 시스템 트리거에 의해서 생성되는 임시테이블이다.
    -- 잠시 이전 데이터를 보관하는 것이다.
	insert into backup_usertbl values (
		old.userid, old.username, old.birthyear, old.addr,
        old.mobile1, old.mobile2, old.height, old.mdate,
        '수정', sysdate(), current_user()
    );

end //
delimiter ;

select *
  from backup_usertbl;
select *
  from usertbl;
-- 데이터를 아래와 같이 수정했다.  
update usertbl
   set addr = '서울'
 where userid = 'KHD';
-- 각 테이블 마다 확인해보자. 
select *
  from backup_usertbl;
select *
  from usertbl;


-- 삭제될 때 작동하는 트리거 만들기
drop trigger if exists backupusertbl_deletetrg;
delimiter //
create trigger backupusertbl_deletetrg
	after delete
    on usertbl
    for each row
begin
	-- 데이터를 delete후 자동으로 실행되는 트리거의 내용이다.
	-- 여기서 old는 시스템 트리거에 의해서 생성되는 임시테이블이다.
    -- 잠시 이전 데이터를 보관하는 것이다.
	insert into backup_usertbl values (
		old.userid, old.username, old.birthyear, old.addr,
        old.mobile1, old.mobile2, old.height, old.mdate,
        '삭제', sysdate(), current_user()
    );

end //
delimiter ;

-- 데이터를 삭제했다.
delete from usertbl
 where height < 180;
-- 데이터를 확인해보도록 하자. 
select *
  from backup_usertbl;
select *
  from usertbl;

-- truncate는 어떻게 되었을까? DML이 아니라 DDL이라서 트랜잭션을 발생시키지 아니한다.
-- 트리거가 작동하지 않는다.  
truncate usertbl;

-- ---------------------------------------------
-- 권한 설정시에 일반 유저한테나 초보 전산직이라면 truncate권한을 주지 않도록 하자.
-- 권한 설정으로 insert나 delete, update등을 사용자 별로 제한할 수도 있지만,
-- 아래와 같이 강제로 오류를 발생시켜 테이블에 입력을 못하도록 막을 수도 있다.
drop trigger if exists usertbl_inserttrg;
delimiter //
create trigger usertbl_inserttrg
	after insert
    on usertbl
    for each row
begin
	signal sqlstate '45000'   -- 프로그래머가 강제로 오류를 발생시키도록 만드는 코드
	-- 출력창에 뿌려주는 내용 설정
    set message_text = '데이터를 저장할 수 없습니다.전산팀에 문의하세요';
end //
delimiter ;

insert into usertbl values('BBC', '비비씨', 1978, '대구', '010' ,'0000000', 176, '2013-05-15');
select *
  from usertbl;

-- 하지만 위와 같이 하는 방법은 별로 권장하지 않는다.
-- 위처럼 일일히 테이블마다 해주면 비효율적이다.그냥 저런 방법도 있구나 정도만 알면된다.

-- 트리거는 임시테이블을 생성한다.즉, 앞서 잠깐 보았던 new, old가 바로 시스템에
-- 있는 임시테이블인 것이다.
-- 하여, insert시에는 new임시테이블만 생성
-- delete는 old임시테이블만 생성
-- update는 new, old임시테이블 둘 다 있다.기억하도록 합니다.

-- before트리거에 대해서 알아보도록 하자
-- before트리거는 테이블에 데이터를 저장하기 전에 new임시테이블로 값들의 유효성을
-- 미리 검사를 할 수가 있다.하여 잘못된 입력값을 바꿔서 입력시킬 수도 있다.

use sqldb;
drop trigger if exists usertbl_beforeinserttrg;
delimiter //
create trigger usertbl_beforeinserttrg
	before insert
    on usertbl
    for each row
begin
    -- 1900년 미만의 데이터가 입력되면 0으로 저장함
	if(new.birthyear < 1900) then
		set new.birthyear = 0;
	-- 현재 년도 보다 더 높은 년도가 입력되면 현재 년도로 저장함.       
	elseif(new.birthyear > year(curdate())) then
		set new.birthyear = year(curdate());
	end if;    
end //
delimiter ;
-- 출생년도가 1750년도로 잘못 입력되어 있어서 출생 년도가 0으로 저장되어진다.
insert into usertbl values ('CCC','씨씨씨', 1750, '천안', '010', '111111', 176,'2017-10-10');
-- 출생년도가 2170년도로 잘못 입력되어 있어서 출생 년도가 2020으로 저장되어진다.
insert into usertbl values ('AAA','에이에', 2170, '한국', '010', '111111', 176,'2017-10-10');
select *
  from usertbl;
  
-- 해당DB에 있는 트리거를 직접 확인하는 코드
show triggers from sqldb;
-- 트리거 삭제 방법
drop trigger usertbl_beforeinserttrg;






