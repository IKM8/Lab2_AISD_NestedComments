PROGRAM Lab2;
{
  PascalABC.NET 4.0
  Группа ПС-21. Глушков Никита
  2 Лабораторная работа
  Вариант 21.
  В некотором компиляторе ПАСКАЛя текст программы включает примечания,
  выделенные фигурными скобками или парами символов (* и *).
  Примечания могут быть вложенными друг в друга. Если примечание открыто
  фигурной скобкой, то оно должно быть закрыто фигурной скобкой. Если
  примечание начинается с пары символов (*, оно должно заканчиваться
  парой символов *).
  Требуется:
  1) проверить правильность вложенности примечаний;
  2) переписать файл с исходным текстом так, чтобы отсутствовала
     вложенность комментариев при сохранении их содержания и в качестве
     ограничивающих символов остались только фигурные скобки.
     Учесть случай, когда символы примечаний находятся в апострофах.
     При некорректности указать номера строки и позиции первой ошибки (10).
  Источники:
}

CONST
  MaxSize = 1000;

VAR
  F, G: TEXT;
  InName, OutName, S: STRING;
  StackKind: ARRAY[1..MaxSize] OF CHAR;    { 'C' - '{',  'P' - '(*' }
  StackLine: ARRAY[1..MaxSize] OF INTEGER;
  StackCol: ARRAY[1..MaxSize] OF INTEGER;
  Top: INTEGER;                           
  InStr: BOOLEAN;
  N, I, LineNum, ErrLine, ErrCol: INTEGER;
  Answer: CHAR;
  Again, Overflow: BOOLEAN;

{ добавить открывающий символ в стек }
PROCEDURE Push(Kind: CHAR; L, C: INTEGER);
BEGIN
  IF Top < MaxSize THEN
  BEGIN
    Top := Top + 1;
    StackKind[Top] := Kind;
    StackLine[Top] := L;
    StackCol[Top] := C;
  END
  ELSE
    Overflow := TRUE;
END;

PROCEDURE Pop;
BEGIN
  Top := Top - 1;
END;

{ тип верхнего открывающего символа }
FUNCTION StackTopKind: CHAR;
BEGIN
  IF Top = 0 THEN
    StackTopKind := ' '  
  ELSE
    StackTopKind := StackKind[Top];
END;

BEGIN
  Again := TRUE;

  WHILE Again DO
  BEGIN
    Top := 0;
    InStr := FALSE;
    LineNum := 0;
    ErrLine := 0;
    ErrCol := 0;
    Overflow := FALSE;

    WRITE('Введите имя входного файла: ');
    READLN(InName);
    WRITE('Введите имя выходного файла: ');
    READLN(OutName);

    ASSIGN(F, InName);
    TRY
      RESET(F);
    EXCEPT
      WRITELN('Не удалось открыть входной файл!');
      BREAK;
    END;

    ASSIGN(G, OutName);
    TRY
      REWRITE(G);
    EXCEPT
      WRITELN('Не удалось создать выходной файл!');
      BREAK;
    END;

    WHILE (NOT EOF(F)) AND (ErrLine = 0) AND (NOT Overflow) DO
    BEGIN
      READLN(F, S);
      LineNum := LineNum + 1;
      N := LENGTH(S);
      I := 1;

      WHILE (I <= N) AND (ErrLine = 0) AND (NOT Overflow) DO
      BEGIN
        IF InStr THEN
        BEGIN
          WRITE(G, S[I]);
          IF S[I] = #39 THEN
            InStr := FALSE;
          I := I + 1;
        END
        ELSE IF Top = 0 THEN
        BEGIN
          { вне комментария }
          IF S[I] = #39 THEN
          BEGIN
            InStr := TRUE;
            WRITE(G, S[I]);
            I := I + 1;
          END
          ELSE IF S[I] = '{' THEN
          BEGIN
            Push('C', LineNum, I);
            WRITE(G, '{');
            I := I + 1;
          END
          ELSE IF (S[I] = '(') AND (I < N) AND (S[I + 1] = '*') THEN
          BEGIN
            Push('P', LineNum, I);
            WRITE(G, '{');
            I := I + 2;
          END
          ELSE IF S[I] = '}' THEN
          BEGIN
            ErrLine := LineNum;
            ErrCol := I;
          END
          ELSE IF (S[I] = '*') AND (I < N) AND (S[I + 1] = ')') THEN
          BEGIN
            ErrLine := LineNum;
            ErrCol := I;
          END
          ELSE
          BEGIN
            WRITE(G, S[I]);
            I := I + 1;
          END;
        END
        ELSE
        BEGIN
          { внутри комментария }
          IF S[I] = '{' THEN
          BEGIN
            Push('C', LineNum, I);
            I := I + 1;
          END
          ELSE IF (S[I] = '(') AND (I < N) AND (S[I + 1] = '*') THEN
          BEGIN
            Push('P', LineNum, I);
            I := I + 2;
          END
          ELSE IF S[I] = '}' THEN
          BEGIN
            IF StackTopKind = 'C' THEN
            BEGIN
              Pop;
              IF Top = 0 THEN
                WRITE(G, '}');
              I := I + 1;
            END
            ELSE
            BEGIN
              ErrLine := LineNum;
              ErrCol := I;
            END;
          END
          ELSE IF (S[I] = '*') AND (I < N) AND (S[I + 1] = ')') THEN
          BEGIN
            IF StackTopKind = 'P' THEN
            BEGIN
              Pop;
              IF Top = 0 THEN
                WRITE(G, '}');
              I := I + 2;
            END
            ELSE
            BEGIN
              ErrLine := LineNum;
              ErrCol := I;
            END;
          END
          ELSE
          BEGIN
            WRITE(G, S[I]);
            I := I + 1;
          END;
        END;
      END;

      IF ErrLine = 0 THEN
        WRITELN(G);
    END;

    IF ErrLine = 0 THEN
    BEGIN
      IF Top <> 0 THEN
      BEGIN
        ErrLine := StackLine[Top];
        ErrCol := StackCol[Top];
      END;
    END;

    IF Overflow THEN
    BEGIN
      WRITELN('слишком глубокая вложенность комментариев');
      WRITELN(G, 'слишком глубокая вложенность комментариев');
    END
    ELSE IF ErrLine <> 0 THEN
    BEGIN
      WRITELN('Ошибка в строке ', ErrLine, ', позиция ', ErrCol);
      WRITELN(G, 'Ошибка в строке ', ErrLine, ', позиция ', ErrCol);
    END
    ELSE
    BEGIN
      WRITELN('Обработка завершена успешно.');
    END;

    CLOSE(F);
    CLOSE(G);

    Top := 0;

    WRITE('Продолжить работу? (y/n): ');
    READLN(Answer);
    IF (Answer = 'y') OR (Answer = 'Y') THEN
      Again := TRUE
    ELSE
      Again := FALSE;
  END;
END.