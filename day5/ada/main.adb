with Ada.Text_IO; use Ada.Text_IO;
with Interfaces;

procedure Main is
	type Board_Cell is (Potential_Land, Land, Water, Sand, Tree, New_Tree);
	type Board_Type is array (Positive range <>, Positive range <>) of Board_Cell;

	function Create_Board(Width: Positive; Height: Positive) return Board_Type
		with Pre => Width mod 2 = 1 and Height mod 2 = 1
	is
		Result: Board_Type(1..Height, 1..Width) := ( others => ( others => Water ));
	begin
		return Result;
	end Create_Board;

	function Read_Board(Filename: String) return Board_Type is
		function Read_Width return Positive is
			File: File_Type;
			Width: Natural;
		begin
			Open(File, In_File, Filename);
			declare
				Line: String := Get_Line(File);
			begin
				Width := Line'Length;
			end;
			Close(File);
			return Positive(Width);
		end;

		function Read_Height return Positive is
			File: File_Type;
			Height: Natural := 0;
		begin
			Open(File, In_File, Filename);
			while not End_Of_File(File) loop
				declare
					Line: String := Get_Line(File);
				begin
					Height := Height + 1;
				end;
			end loop;
			Close(File);
			return Positive(Height);
		end;
		
		Width: Positive := Read_Width;
		Height: Positive := Read_Height;
		Result: Board_Type := Create_Board(Width, Height);

		subtype Row_Index is Positive range Result'Range(1);
		subtype Column_Index is Positive range Result'Range(2);

		File: File_Type;
	begin
		Open(File, In_File, Filename);
		for Row in Row_Index loop
			declare
				Line: String := Get_Line(File);
			begin
				for Column in Column_Index loop
					Result(Row, Column) := (if Line(Column) = '1' then Potential_Land else Water);
				end loop;
			end;
		end loop;
		Close(File);
		return Result;
	end Read_Board;

	procedure Fill_Land(
		Board: in out Board_Type;
		Row_In: Positive;
		Column_In: Positive;
		Num_Land: in out Natural
	)
	is
		subtype Row_Index is Positive range Board'Range(1);
		subtype Column_Index is Positive range Board'Range(2);	

		function Is_Land(Row: Row_Index; Column: Column_Index) return Boolean is
			Count: Natural := 0;
		begin
			for Row_Offset in Integer range -1..1 loop
				for Column_Offset in Integer range -1..1 loop
					declare
						R: Integer := Integer(Row) + Row_Offset;
						C: Integer := Integer(Column) + Column_Offset;
					begin
						if (R in Row_Index and C in Column_Index)
							and then 
							(Board(R, C) = Potential_Land or Board(R, C) = Land)
						then
							Count := Count + 1;
						end if;
					end;
				end loop;
			end loop;

			if Board(Row, Column) /= Water then
				Count := Count - 1;
			end if;
			
			return Count >= 5;
		end Is_Land;

		Row: Row_Index := Row_In;
		Column: Column_Index := Column_In;
	begin
		if not Is_Land(Row, Column) then
			return;
		end if;
		
		Num_Land := Num_Land + 1;
		Board(Row, Column) := Land;
		for Row_Offset in Integer range -1..1 loop
			for Column_Offset in Integer range -1..1 loop
				declare
					R: Integer := Integer(Row) + Row_Offset;
					C: Integer := Integer(Column) + Column_Offset;
				begin
					if (R in Row_Index and C in Column_Index) 
						and then Board(R, C) /= Land
					then
						Fill_Land(Board, Row_Index(R), Column_Index(C), Num_Land);
					end if;
				end;
			end loop;
		end loop;
	end Fill_Land;

	procedure Fill_Sand(Board: in out Board_Type; Num_Sand: in out Natural) is
		subtype Row_Index is Positive range Board'Range(1);
		subtype Column_Index is Positive range Board'Range(2);	

		function Should_Become_Sand(
			Row: Row_Index;
			Column: Column_Index;
			Target_Cell: Board_Cell;
			Target_Count: Natural)
		return Boolean is
			Count: Natural := 0;
		begin
			if Board(Row, Column) /= Land then
				return false;
			end if;

			for Row_Offset in Integer range -1..1 loop
				for Column_Offset in Integer range -1..1 loop
					declare
						R: Integer := Integer(Row) + Row_Offset;
						C: Integer := Integer(Column) + Column_Offset;
					begin
						if (R not in Row_Index or C not in Column_Index)
							or else Board(R, C) = Target_Cell
						then
							Count := Count + 1;
						end if;
					end;
				end loop;
			end loop;

			return Count >= Target_Count;			
		end Should_Become_Sand;

		Loop_Again: Boolean := true;
	begin
		-- Potential_Land is now considered Water
		for Row in Row_Index loop
			for Column in Column_Index loop
				if Board(Row, Column) = Potential_Land then
					Board(Row, Column) := Water;
				end if;
			end loop;
		end loop;

		-- Fill in sand on the coast
		for Row in Row_Index loop
			for Column in Column_Index loop
				if Should_Become_Sand(Row, Column, Water, 1) then
					Board(Row, Column) := Sand;
					Num_Sand := Num_Sand + 1;
				end if;
			end loop;
		end loop;

		-- Iterate over the board until there's no more sand to place
		while Loop_Again loop
			Loop_Again := false;
			for Row in Row_Index loop
				for Column in Column_Index loop
					if Should_Become_Sand(Row, Column, Sand, 5) then
						Board(Row, Column) := Sand;
						Num_Sand := Num_Sand + 1;
						Loop_Again := true;
					end if;
				end loop;
			end loop;
		end loop;
	end Fill_Sand;

	procedure Fill_Trees(Board: in out Board_Type; Num_Trees: in out Natural) is
		subtype Row_Index is Positive range Board'Range(1);
		subtype Column_Index is Positive range Board'Range(2);

		function Should_Become_Tree_First(Row: Row_Index; Column: Column_Index) return Boolean is
		begin
			if not (Board(Row, Column) = Land) then
				return false;
			end if;
		
			for Row_Offset in Integer range -2..2 loop
				for Column_Offset in Integer range -2..2 loop
					declare
						R: Integer := Integer(Row) + Row_Offset;
						C: Integer := Integer(Column) + Column_Offset;
					begin
						if not (
							(Row_Offset = -2 and Column_Offset = -2) or
							(Row_Offset =  2 and Column_Offset =  2) or
							(Row_Offset =  2 and Column_Offset = -2) or
							(Row_Offset = -2 and Column_Offset =  2))
						then
							if (R not in Row_Index or C not in Column_Index) or else
								(Board(R, C) /= Land and Board(R, C) /= Tree)
							then
								return false;
							end if;
						end if;
					end;
				end loop;
			end loop;
			
			return true;
		end Should_Become_Tree_First;

		function Should_Become_Tree_Later(Row: Row_Index; Column: Column_Index) return Boolean is
			Count: Natural := 0;
		begin
			if Board(Row, Column) /= Land then
				return false;
			end if;

			for Row_Offset in Integer range -1..1 loop
				for Column_Offset in Integer range -1..1 loop
					declare
						R: Integer := Integer(Row) + Row_Offset;
						C: Integer := Integer(Column) + Column_Offset;
					begin
						if (R not in Row_Index or C not in Column_Index) or else
							(Board(R, C) = Sand)
						then
							return false;
						end if;

						if Board(R, C) = Tree then
							Count := Count + 1;
						end if;
					end;
				end loop;
			end loop;
			
			return Count >= 4;			
		end Should_Become_Tree_Later;		
	begin
		-- Place first trees
		for Row in Row_Index loop
			for Column in Column_Index loop
				if Should_Become_Tree_First(Row, Column) then
					Board(Row, Column) := Tree;
					Num_Trees := Num_Trees + 1;
				end if;
			end loop;
		end loop;

		-- Place later trees twice
		for I in 1..2 loop
			for Row in Row_Index loop
				for Column in Column_Index loop
					if Should_Become_Tree_Later(Row, Column) then
						Board(Row, Column) := New_Tree;
						Num_Trees := Num_Trees + 1;
					end if;
				end loop;
			end loop;
			
			for Row in Row_Index loop
				for Column in Column_Index loop
					if Board(Row, Column) = New_Tree then
						Board(Row, Column) := Tree;
					end if;
				end loop;
			end loop;		
		end loop;
	end Fill_Trees;	
	
	function Part_One(Filename: String) return Natural is
		Board: Board_Type := Read_Board(Filename);
		subtype Row_Index is Positive range Board'Range(1);
		subtype Column_Index is Positive range Board'Range(2);	
		
		Middle_Row: Row_Index := (Row_Index'Last - Row_Index'First + 1) / 2;
		Middle_Column: Column_Index := (Column_Index'Last - Column_Index'First + 1) / 2;
		Result: Natural := 0;
	begin
		Fill_Land(Board, Middle_Row, Middle_Column, Result);
		return Result;
	end Part_One;

	function Part_Two(Filename: String) return Natural is
		Board: Board_Type := Read_Board(Filename);
		subtype Row_Index is Positive range Board'Range(1);
		subtype Column_Index is Positive range Board'Range(2);	
		
		Middle_Row: Row_Index := (Row_Index'Last - Row_Index'First + 1) / 2;
		Middle_Column: Column_Index := (Column_Index'Last - Column_Index'First + 1) / 2;
		Num_Land: Natural := 0;
		Num_Sand: Natural := 0;
	begin
		Fill_Land(Board, Middle_Row, Middle_Column, Num_Land);
		Fill_Sand(Board, Num_Sand);
		return Num_Sand;
	end Part_Two;

	function Part_Three(Filename: String) return Natural is
		Board: Board_Type := Read_Board(Filename);
		subtype Row_Index is Positive range Board'Range(1);
		subtype Column_Index is Positive range Board'Range(2);	
		
		Middle_Row: Row_Index := (Row_Index'Last - Row_Index'First + 1) / 2;
		Middle_Column: Column_Index := (Column_Index'Last - Column_Index'First + 1) / 2;
		Num_Land: Natural := 0;
		Num_Sand: Natural := 0;
		Num_Trees: Natural := 0;
	begin
		Fill_Land(Board, Middle_Row, Middle_Column, Num_Land);
		Fill_Sand(Board, Num_Sand);
		Fill_Trees(Board, Num_Trees);
		return Num_Trees;
	end Part_Three;

begin
	declare
		X: Natural := Part_One("test1.txt");
	begin
		pragma Assert(X = 137, "got" & X'Image);
	end;
	Put_Line("Part 1: " & Part_One("everybody_codes_e2026_q05_p1.txt")'Image);
	
	declare
		X: Natural := Part_Two("test2.txt");
	begin
		pragma Assert(X = 69, "got" & X'Image);
	end;
	Put_Line("Part 2: " & Part_Two("everybody_codes_e2026_q05_p2.txt")'Image);

	declare
		X: Natural := Part_Three("test3.txt");
	begin
		pragma Assert(X = 14, "got" & X'Image);
	end;
	Put_Line("Part 3: " & Part_Three("everybody_codes_e2026_q05_p3.txt")'Image);
end Main;
