use sqldb;

-- 스토어드 프로시져에서 오류처리에 관련된 코드
drop procedure if exists errorproc;
delimiter //
create procedure errorproc()
begin
	declare i int;  -- 1씩 증가하는 값
    -- 합계(정수형), 오버플로 발생시킬 예정(그래야 오류처리 핸들러가 작동하니깐)
    declare hap int;  
    declare savehap int;  -- 합계(정수형), 오버플로 직접의 값을 출력하는 용도
    
    -- 오버플로우 발생하면 실행하는 handler를 등록
    declare exit handler for sqlexception
    begin
		show errors;  -- 오류코드를 보여준다.
		select concat('int데이터 타입의 오버플로우 직전의 합계 : ', savehap);
        select concat('오버플로우 직전의 i의 값 : ', i);
    end;
    
    set i = 0;
    set hap = 0;
    -- 아래 반복문은 무한루프를 돈다.
    while(1) do
		set savehap = hap; -- 오버플로 직전의 합계
        set hap = hap + i; -- 여기서 오버플로 발생예정, 발생되면 핸들러가 실행
        set i = i + 1;
	end while;
end //
delimiter ;

call errorproc();

-- 만들어 놓은 프로시져의 즉 현재 저장된 프로시져의 이름 및 내용을 알고자 할때는
-- 아래와 같이 시스템DB 이용하여 출력해보면 된다.
select routine_name, routine_definition
  from information_schema.routines  -- 시스템DB의 routines라는 테이블
 where routine_schema = 'sqldb'
   and routine_type = 'PROCEDURE';  

-- 프로시져의 매개변수의 값을 알고자 한다면 시스템DB를 이용하면 된다.
select specific_name, parameter_mode, data_type, dtd_identifier
  from information_schema.parameters;

-- 특정 DB에 있는 특정 프로시져만 보고 싶다면 아래 코드로 작성을 하면 된다.
show create procedure sqldb.userproc3;

-- 테이블명을 입력 매개변수로 가지는 코드
drop procedure if exists nameproc;
delimiter //
create procedure nameproc(in tblname varchar(20))  -- 테이블 이름이 매개변수이다.
begin
	declare exit handler for sqlexception
    begin
		show errors;  -- 오류코드를 보여준다.
	end;
	select concat('tblname : ', tblname);
    select *
	  from tblname;
end //
delimiter ;

-- 호출을 해보면 오류가 난다.
-- 원래 기본적으로 매개변수으로는 테이블명은 넘어갈 수가 없다.
call nameproc('usertbl');

-- 위와 같은 경우는 동적sql문을 이용해서 사용하면 된다.
drop procedure if exists nameproc;
delimiter //
create procedure nameproc(in tblname varchar(20))
begin
	-- 변수에 쿼리문을 저장함
	set @sqlquery = concat('select * from ',tblname);	
    -- 동적sql구문을 myquery에 준비를 한다.
	prepare myquery from @sqlquery;
	execute myquery;  -- 준비된 sql문을 실행한다.
    deallocate prepare myquery;  -- 메모리에 할당된 동적 sql문을 해제한다.
end //
delimiter ;

call nameproc('usertbl');