:- use_module(library(pce)).
:- pce_global(@name_prompter, make_name_prompter).

% Cargar la base de conocimientos del yerberito
:- consult('yerberito.pl').

make_name_prompter(P) :-
    new(P, dialog),
    send(P, kind, transient),
    send(P, append, label(prompt)),
    send(P, append,
        new(TI, text_item(name, '', message(P?ok_member, execute)))),
    send(P, append, button(ok, message(P, return, TI?selection))),
    send(P, append, button(cancel, message(P, return, @nil))).

% Predicado para mostrar imágenes
mostrar(V, D):- 
    new(I, image(V)),
    new(B, bitmap(I)),
    new(F, figure),
    send(F, display, B),
    new(Device, device),
    send(Device, display, F),
    send(D, display, Device, point(0, 0)).

% Ventana inicial con los botones e imagen
main :-
    new(V, dialog('Menu Principal', size(640, 480))),
    send(V, append, new(Menu, label(texto, 'Bienvenido al Yerberito Ilustrado'))),
    mostrar('D:/imgYerberito/yerberito.jpg', V),
    send(V, append, new(B1, button('Consultar por Planta', message(@prolog, abrir_consulta_por_planta)))),
    send(V, append, new(B2, button('Consultar por Sintoma', message(@prolog, abrir_consulta_por_sintoma)))),
    send(V, append, new(B3, button('Mostrar Imagen', message(@prolog, abrir_mostrar_imagen)))),
    send(V, append, new(B4, button('Botiquin de Plantas', message(@prolog, mostrar_botiquin)))),
    send(V, append, new(B5, button('Consultar por Medicamento', message(@prolog, abrir_consulta_por_medicamento)))),
    send(B1, below, Menu),
    send(B2, below, B1),
    send(B3, below, B2),
    send(B4, below, B3),
    send(B5, below, B4),
    send(V, open).

% Predicado para abrir la ventana para mostrar la imagen de una planta
abrir_mostrar_imagen :-
    new(D, dialog('Mostrar Imagen de la Planta', size(640, 400))),
    send(D, append, new(Planta, menu(nombre, cycle))),
    cargar_plantas(Planta),
    send(D, append, button(mostrar, message(@prolog, mostrar_imagen, Planta?selection, D))),
    send(D, open).

% Predicado para cargar las plantas en el menú desplegable
cargar_plantas(Menu) :-
    findall(Nombre, planta(Nombre, _), Plantas),
    sort(Plantas, PlantasUnicas), % Eliminar duplicados
    forall(member(Planta, PlantasUnicas),
           send(Menu, append, Planta)).

% Predicado para cargar los síntomas en el menú desplegable
cargar_sintomas(Menu) :-
    findall(Sintoma, planta(_, Sintoma), Sintomas),
    sort(Sintomas, SintomasUnicas), % Eliminar duplicados
    forall(member(Sintoma, SintomasUnicas),
           send(Menu, append, Sintoma)).

% Predicado para cargar los medicamentos en el menú desplegable
cargar_medicamentos(Menu) :-
    findall(Medicamento, medicamento(_, Medicamento), Medicamentos),
    sort(Medicamentos, MedicamentosUnicos), % Eliminar duplicados
    forall(member(Med, MedicamentosUnicos),
           send(Menu, append, Med)).

% Predicado para abrir la ventana de consulta por planta
abrir_consulta_por_planta :-
    new(D, dialog('Consulta por Planta', size(640, 400))),
    send(D, append, new(Planta, menu(nombre, cycle))),
    cargar_plantas(Planta),
    send(D, append, button(consultar, message(@prolog, consultar_planta, Planta?selection, D))),
    send(D, open).

% Predicado para abrir la ventana de consulta por síntoma
abrir_consulta_por_sintoma :-
    new(D, dialog('Consulta por Sintoma', size(640, 400))),
    send(D, append, new(Sintoma, menu(nombre, cycle))),
    cargar_sintomas(Sintoma),
    send(D, append, button(consultar, message(@prolog, consultar_sintoma, Sintoma?selection, D))),
    send(D, open).

% Predicado para abrir la ventana de consulta por medicamento
abrir_consulta_por_medicamento :-
    new(D, dialog('Consulta por Medicamento', size(640, 400))),
    send(D, append, new(Medicamento, menu(nombre, cycle))),
    cargar_medicamentos(Medicamento),
    send(D, append, button(consultar, message(@prolog, consultar_medicamento, Medicamento?selection, D))),
    send(D, open).

% Predicado para manejar la consulta de la planta
consultar_planta(NombrePlanta, D) :-
    downcase_atom(NombrePlanta, NombrePlantaMin),
    new(ResultDialog, dialog('Resultados de la Consulta', size(640, 800))), % Ventana más larga
    findall(Uso, planta(NombrePlantaMin, Uso), Usos),
    findall(Preparacion, (plantas_preparacion(NombrePlantaMin, PreparacionList), member(Preparacion, PreparacionList)), Preparaciones),
    findall(Medicamento, medicamento(NombrePlantaMin, Medicamento), Medicamentos),
    (   componente_quimico(NombrePlantaMin, ComponentesQuimicos)
    ->  true
    ;   ComponentesQuimicos = []
    ),
    (   nombre_cientifico(NombrePlantaMin, NombreCientifico)
    ->  true
    ;   NombreCientifico = 'Desconocido'
    ),
    (   origen(NombrePlantaMin, Origen)
    ->  mostrar_resultados(NombrePlantaMin, NombreCientifico, Usos, Preparaciones, Medicamentos, ComponentesQuimicos, Origen, ResultDialog)
    ;   mostrar_resultados(NombrePlantaMin, NombreCientifico, Usos, Preparaciones, Medicamentos, ComponentesQuimicos, 'Desconocido', ResultDialog)
    ),
    send(ResultDialog, append, button(cerrar, message(ResultDialog, destroy))),
    send(ResultDialog, open).

% Predicado para manejar la consulta por síntoma
consultar_sintoma(Sintoma, D) :-
    new(ResultDialog, dialog('Resultados de la Consulta por Sintoma', size(640, 800))), % Ventana más larga
    findall(NombrePlanta, planta(NombrePlanta, Sintoma), Plantas),
    sort(Plantas, PlantasUnicas),
    mostrar_resultados_por_sintoma(Sintoma, PlantasUnicas, ResultDialog),
    send(ResultDialog, append, button(cerrar, message(ResultDialog, destroy))),
    send(ResultDialog, open).

% Predicado para manejar la consulta por medicamento
consultar_medicamento(Medicamento, D) :-
    new(ResultDialog, dialog('Resultados de la Consulta por Medicamento', size(640, 800))), % Ventana más larga
    findall(NombrePlanta, medicamento(NombrePlanta, Medicamento), Plantas),
    sort(Plantas, PlantasUnicas),
    mostrar_resultados_por_medicamento(Medicamento, PlantasUnicas, ResultDialog),
    send(ResultDialog, append, button(cerrar, message(ResultDialog, destroy))),
    send(ResultDialog, open).

% Predicado para mostrar resultados en el diálogo por planta
mostrar_resultados(_, _, [], [], [], [], _, Dialog) :-
    send(Dialog, append, label(texto, 'No se encontraron usos medicinales, metodos de preparacion, componentes quimicos ni origen.')).
mostrar_resultados(NombrePlanta, NombreCientifico, [Uso|Usos], Preparaciones, Medicamentos, ComponentesQuimicos, Origen, Dialog) :-
    send(Dialog, append, label(texto, string('La planta %s (%s) se usa para: %s', NombrePlanta, NombreCientifico, Uso))),
    mostrar_resultados(NombrePlanta, NombreCientifico, Usos, Preparaciones, Medicamentos, ComponentesQuimicos, Origen, Dialog).
mostrar_resultados(NombrePlanta, NombreCientifico, [], Preparaciones, Medicamentos, ComponentesQuimicos, Origen, Dialog) :-
    send(Dialog, append, label(texto, string('Origen: %s', Origen))),
    (   Preparaciones \= []
    ->  send(Dialog, append, label(texto, 'Metodos de preparacion:')),
        mostrar_preparaciones(Preparaciones, Dialog)
    ;   true
    ),
    (   Medicamentos \= []
    ->  send(Dialog, append, label(texto, 'Medicamentos:')),
        mostrar_medicamentos(Medicamentos, Dialog)
    ;   true
    ),
    (   ComponentesQuimicos \= []
    ->  send(Dialog, append, label(texto, 'Componentes quimicos:')),
        mostrar_componentes_quimicos(ComponentesQuimicos, Dialog)
    ;   true
    ).

% Predicado para mostrar métodos de preparación
mostrar_preparaciones([], _).
mostrar_preparaciones([P|Ps], Dialog) :-
    send(Dialog, append, label(texto, string('- %s', P))),
    mostrar_preparaciones(Ps, Dialog).

% Predicado para mostrar componentes químicos
mostrar_componentes_quimicos([], _).
mostrar_componentes_quimicos([C|Cs], Dialog) :-
    send(Dialog, append, label(texto, string('- %s', C))),
    mostrar_componentes_quimicos(Cs, Dialog).

% Predicado para mostrar medicamentos
mostrar_medicamentos([], _).
mostrar_medicamentos([M|Ms], Dialog) :-
    send(Dialog, append, label(texto, string('- %s', M))),
    mostrar_medicamentos(Ms, Dialog).

% Predicado para mostrar resultados en el diálogo por síntoma
mostrar_resultados_por_sintoma(_, [], Dialog) :-
    send(Dialog, append, label(texto, 'No se encontraron plantas que curen ese sintoma.')).
mostrar_resultados_por_sintoma(Sintoma, [Planta|Plantas], Dialog) :-
    consultar_planta(Planta, Dialog),
    mostrar_resultados_por_sintoma(Sintoma, Plantas, Dialog).

% Predicado para mostrar resultados en el diálogo por medicamento
 mostrar_resultados_por_medicamento(_, [], Dialog) :-
    send(Dialog, append, label(texto, 'No se encontraron plantas que contengan este medicamento.')).
mostrar_resultados_por_medicamento(Medicamento, [Planta|Plantas], Dialog) :-
    consultar_planta(Planta, Dialog),
    mostrar_resultados_por_medicamento(Medicamento, Plantas, Dialog).

% Predicado para mostrar el botiquín de plantas
mostrar_botiquin :-
    new(D, dialog('Botiquin de Plantas', size(640, 400))),
    botiquin(ListaPlantas),
    mostrar_botiquin(ListaPlantas, D),
    send(D, append, button(cerrar, message(D, destroy))),
    send(D, open).

% Predicado para generar el botiquín de plantas
botiquin(ListaPlantas) :-
    findall(Planta, planta(Planta, _), PlantasRepetidas),
    list_to_set(PlantasRepetidas, Plantas),
    random_permutation(Plantas, Permutacion),
    length(Botiquin, 5),
    append(Botiquin, _, Permutacion),
    ListaPlantas = Botiquin.

% Predicado para mostrar el botiquín de plantas en el diálogo
mostrar_botiquin([], _).
mostrar_botiquin([P|Ps], Dialog) :-
    send(Dialog, append, label(texto, P)),
    mostrar_botiquin(Ps, Dialog).

% Lanzar la interfaz
:- main.
