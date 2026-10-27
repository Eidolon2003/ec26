with Ada.Text_IO; use Ada.Text_IO;
with Ada.Containers.Vectors;
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

procedure Main is
	-- Instantiate the standard vector container for Integer
	package Integer_Vectors is new Ada.Containers.Vectors (
		Index_Type => Natural, Element_Type => Integer	
	);
	subtype Vec is Integer_Vectors.Vector;

	-- Takes a filename string and returns a vector containing the puzzle input
	function Read_Input(Filename: String) return Vec is
		File: File_Type;
		Result: Vec;
	begin
		Open(File, In_File, Filename);

		-- Parse the comma separated list of Integers
		declare
			Line: constant String := Get_Line(File);
			N_Index: Positive := Line'First;
			N: Integer;
		begin
			-- Find each comma, and parse the number up to that comma
			for I in Line'Range loop
				if Line(I) = ',' then
					N := Integer'Value(Line(N_Index..I-1));
					N_Index := I + 1;
					Result.Append(N);
				end if;
			end loop;
			-- Catch the number after the final comma
			N := Integer'Value(Line(N_Index..Line'Last));
			Result.Append(N);
		end;

		Close(File);
		return Result;
	end Read_Input;

	function Part_One(Filename: String) return Integer is
		Input: Vec := Read_Input(Filename);
		Result: Integer := 0;
		Float_Root: Float;
		Integer_Root: Integer;
	begin
		for Element of Input loop
			Float_Root := Sqrt(Float(Element));
			Integer_Root := Integer(Float'Floor(Float_Root));
			if Float(Integer_Root) /= Float_Root then
				Integer_Root := Integer_Root + 1;
				Result := Result + (Integer_Root*Integer_Root) - Element;
			end if;
		end loop;

		return Result;
	end Part_One;

	function Part_Two(Filename: String) return Integer is
		Input: Vec := Read_Input(Filename);
		Result: Integer := 0;
	begin
		for Element of Input loop
			declare
				N: Integer;
			begin
				for I in 3..Integer'Last loop
					N := I*I - (I-2)*(I-2);
					if N >= Element then
						exit;
					end if;
				end loop;
				Result := Result + N - Element;
			end;
		end loop;

		return Result;
	end Part_Two;
	
	function Part_Three(Filename: String) return Integer is
		Input: Vec := Read_Input(Filename);
		Result: Integer := 0;
	begin
		for Element of Input loop
			declare
				I: Integer := 3;
				N: Integer;
			begin
				while I <= Integer'Last loop
					N := I*I - 1;
					if N >= Element then
						exit;
					end if;
					I := I + 2;
				end loop;
				Result := Result + N - Element;
			end;
		end loop;

		return Result;
	end Part_Three;

begin
	declare
		X: Integer := Part_One("test1.txt");
	begin
		pragma Assert(X = 11);
	end;
	Put_Line("Part 1: " & Part_One("everybody_codes_e2026_q01_p1.txt")'Image);

	declare
		X: Integer := Part_Two("test2.txt");
	begin
		pragma Assert(X = 9);
	end;
	Put_Line("Part 2: " & Part_Two("everybody_codes_e2026_q01_p2.txt")'Image);

	declare
		X: Integer := Part_Three("test3.txt");
	begin
		pragma Assert(X = 61);
	end;
	Put_Line("Part 3: " & Part_Three("everybody_codes_e2026_q01_p3.txt")'Image);
end Main;
