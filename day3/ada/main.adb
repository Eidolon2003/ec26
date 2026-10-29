with Ada.Text_IO; use Ada.Text_IO;
with Interfaces;

procedure Main is
	type U64 is new Interfaces.Unsigned_64;

	function Char_To_U64(C: Character) return U64 is
		subtype Digit_Range is U64 range 0..9;
	begin
		return Digit_Range(Character'Pos(C) - Character'Pos('0'));
	end Char_To_U64;

	function Find_Space(S: String) return Natural is
	begin
		for I in S'Range loop
			if S(I) = ' ' then
				return I;
			end if;
		end loop;
		pragma Assert(false, "Unreachable");
	end Find_Space;

	function Part_One(Filename: String) return U64 is
		File: File_Type;
		Result: U64 := 0;
	begin
		Open(File, In_File, Filename);

		while not End_Of_File(File) loop
			declare
				Line: constant String := Get_Line(File);
				Base_Index: Natural := Line'First + 4;
				Coef_Index: Natural := Line'First + 9;
			begin
				for Exponent in reverse Natural range 0..3 loop
					Result := Result + Char_To_U64(Line(Coef_Index)) * Char_To_U64(Line(Base_Index)) ** Exponent;
					Base_Index := Base_Index + 1;
					Coef_Index := Coef_Index + 1;
				end loop;
			end;
		end loop;

		Close(File);
		return Result;
	end Part_One;

	function Part_Two(Filename: String) return U64 is
		File: File_Type;
		Result: U64 := 0;
	begin
		Open(File, In_File, Filename);

		while not End_Of_File(File) loop
			declare
				Line: constant String := Get_Line(File);
				Base_Offset: constant Natural := 5;
				Num_Bases: constant Natural := Find_Space(Line) - 5;
				Num_Coefs: constant Natural := Line'Length - Num_Bases - 5;
				
				Base_Index: Natural := Num_Bases - 1;
				Coef_Index: Natural := Line'Last;
			begin
				for Exponent in  Natural range 0..Num_Coefs-1 loop
					Result := Result + Char_To_U64(Line(Coef_Index)) * Char_To_U64(Line(Base_Offset+Base_Index)) ** Exponent;
					Base_Index := (Base_Index - 1) mod Num_Bases;
					Coef_Index := Coef_Index - 1;
				end loop;
			end;
		end loop;

		Close(File);
		return Result;
	end Part_Two;

	function Part_Three(Filename: String) return U64 is
		function Get_Number(S: String) return U64 is
			Index: Natural := Find_Space(S) + 1; 
		begin
			return U64'Value(S(Index..S'Last));
		end Get_Number;

		function Find_Best_Number(Bases: String; Target_Value: U64; Num_Coefs: Natural) return U64 is
			Min_Digits: constant Natural := Num_Coefs;
			Digits_Array: array(0..Min_Digits-1) of U64 := ( others => 0 );
			Current_Value: U64 := 0;
			Best_Number: U64 := 0;

			procedure Increment_Digits is
				N: U64;
			begin
				for I in reverse Digits_Array'Range loop
					N := Digits_Array(I) + 1;
					Digits_Array(I) := N mod 10;
					if N < 10 then
						return;
					end if;
				end loop;
			end Increment_Digits;
		begin
			while Current_Value /= Target_Value loop
				Increment_Digits;
				declare
					Value: U64 := 0;
					Base_Index: Natural := Bases'Last - Bases'First;
				begin
					for Exponent in Digits_Array'Range loop
						Value := Value + Digits_Array(Digits_Array'Last - Exponent) * Char_To_U64(Bases(Bases'First+Base_Index)) ** Exponent;
						Base_Index := (Base_Index - 1) mod Bases'Length;
					end loop;
					Current_Value := Value;
				end;	
			end loop;

			for Element of Digits_Array loop
				Best_Number := 10*Best_Number + Element;
			end loop;
			return Best_Number;
		end Find_Best_Number;
	
		File: File_Type;
		Result: U64 := 0;
	begin
		Open(File, In_File, Filename);

		while not End_Of_File(File) loop
			declare
				Line: constant String := Get_Line(File);
				Base_Offset: constant Natural := 6;
				Num_Bases: constant Natural := Find_Space(Line) - 6;
				Num_Coefs: constant Natural := Line'Length - Num_Bases - 6;
				
				Base_Index: Natural := Num_Bases - 1;
				Coef_Index: Natural := Line'Last;
				This_Result: U64 := 0;
			begin
				for Exponent in  Natural range 0..Num_Coefs-1 loop
					This_Result := This_Result + Char_To_U64(Line(Coef_Index)) * Char_To_U64(Line(Base_Offset+Base_Index)) ** Exponent;
					Base_Index := (Base_Index - 1) mod Num_Bases;
					Coef_Index := Coef_Index - 1;
				end loop;

				declare
					This_Number: U64 := Get_Number(Line);
					Best_Number: U64 := Find_Best_Number(Line(Base_Offset..Base_Offset+Num_Bases-1), This_Result, Num_Coefs);
				begin
					if This_Number = Best_Number then
						Result := Result + This_Result;
					end if;
				end;
			end;
		end loop;

		Close(File);
		return Result;
	end Part_Three;

begin
	declare
		X: U64 := Part_One("test1.txt");
	begin
		pragma Assert(X = 1478, "got" & X'Image);
	end;
	Put_Line("Part 1: " & Part_One("everybody_codes_e2026_q03_p1.txt")'Image);
	
	declare
		X: U64 := Part_Two("test2.txt");
	begin
		pragma Assert(X = 1161463, "got" & X'Image);
	end;
	Put_Line("Part 2: " & Part_Two("everybody_codes_e2026_q03_p2.txt")'Image);

	declare
		X: U64 := Part_Three("test3.txt");
	begin
		pragma Assert(X = 50987, "got" & X'Image);
	end;
	Put_Line("Part 3: " & Part_Three("everybody_codes_e2026_q03_p3.txt")'Image);
end Main;
