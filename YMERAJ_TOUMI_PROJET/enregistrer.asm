; BINOME LIZA TOUMI ET ELDIS Ymeraj 
section .data
    ; Messages du menu
    menu_msg db "Veuillez choisir une opération parmi les 5 suivantes:", 0xA
             db "1. Enregistrer du personnel", 0xA
             db "2. Liste des personnes enregistrées", 0xA
             db "3. Afficher des personnes spécifiques", 0xA
             db "4. Afficher l'âge moyen de toutes les personnes enregistrées (Fonctionalité non-implementé)", 0xA
             db "5. Quitter le programme", 0xA
             db "Votre choix (de 1 à 5) : ", 0
    menu_msg_len equ $ - menu_msg
    input_msg db "Entrez le nom et l'âge de la personne (séparés par un espace) : ", 0
    input_msg_len equ $ - input_msg
    output_msg db "Voici la liste des personnes enregistrées : ", 0xA
    output_msg_len equ $ - output_msg
    avg_age_msg db "L'âge moyen de toutes les personnes : ", 0xA
    liste_personnes_msg db "Liste des personnes: ", 0xA
    liste_personnes_msg_len equ $-liste_personnes_msg
    empty_table_msg db "La table est vide", 0xA
    empty_table_msg_len equ $-empty_table_msg
    
    ; Variable pour stocker le choix de l'utilisateur
    user_choice dd 0       ; 0 par défaut
    
    MAX_PERSONNES_COUNT equ 20 ; Nombre maximal de personnes pouvant être enregistrées
    MAX_PERSONNES equ 32   ; Longueur maximale du nom et de l'âge
    personnes_nom_length equ MAX_PERSONNES_COUNT*MAX_PERSONNES ; Taille du tableau de personnes
    personnes times personnes_nom_length db 0  ; Tableau de personnes
    
    nb_personnes db 0   ; Variable pour suivre le nombre de personnes enregistrées
    listing_index db 0 ;pour l'affichage
    space db ' ', 0    
    search_msg db "Entrez le numéro identifiant de la personne à rechercher : ", 0
    search_msg_len equ $-search_msg
    not_found_msg db "Personne non trouvée !" ,0xA
    not_found_msg_len equ $-not_found_msg
    search dd 0
    newline db 10        ; Nouvelle ligne
    
    number_buffer TIMES 10 db 0     ; Buffer pour stocker le nombre converti (jusqu'à 10 chiffres)
    temp db 0   ; Variable temporaire pour contenir la valeur incrémentée
 
    input_buffer TIMES 32 db 0
    max_age_index dd 0
    invalid_in db "Entrée invalide !" ,0xA
    invalid_in_len equ $-invalid_in
    max_age_msg db "Afficher la personne la plus âgée : ",0xA
    max_age_msg_len equ $-max_age_msg
    max_age dd 0  ; Buffer pour stocker l'âge

section .text
    global _start
_start:
  ; Affichage du menu
jmp display_menu
; Sélection de l'option
jmp manage_choice

enregistrer_personnel:
    ; Nettoyer le tampon d'entrée
    call clear_input_buffer
    mov eax, 4
    mov ebx, 1
    mov ecx, input_msg
    mov edx, input_msg_len
    int 0x80
    
     ; Lire l'entrée de l'utilisateur pour le nom et l'âge
    mov eax, 3      ; Numéro de l'appel système sys_read
    mov ebx, 0      ; Descripteur de fichier (stdin)
    mov ecx, input_buffer  ; Tampon pour stocker le nom et l'âge de l'utilisateur
    mov edx, 32  ; Nombre maximal d'octets à lire pour le nom et l'âge
    int 0x80        ; Appel système pour lire l'entrée depuis stdin
    ; Copier les données du tampon d'entrée vers le tableau personnes
    mov al, byte [nb_personnes] ; Extension zéro de la valeur 16 bits à 32 bits
    mov ecx, 32
    mul ecx                     
    add eax, personnes          
    mov edi, eax                
    mov ecx, 32                 
    mov esi, input_buffer       
    copy_loop:
        mov al, [esi]           
        mov [edi], al           
        inc esi                 
        inc edi                 
        loop copy_loop         
    
    ; Trouver la position du caractère espace
    mov esi, input_buffer   
    find_space:
        cmp byte [esi], 0   
        je invalid_input    
        cmp byte [esi], ' ' 
        je space_found      
        inc esi             
        jmp find_space      
    space_found:
    
    ; Convertir l'âge de ASCII à une valeur numérique
    xor eax, eax            
    xor ebx, ebx            
    mov ecx, 3              
    inc esi                 
    process_age_digits:
        cmp byte [esi], 10 
        je buffer_end_reached       
        cmp byte [esi], '0'  
        jb invalid_input    
        cmp byte [esi], '9'  
        ja invalid_input    
        sub byte [esi], '0' 
        imul eax, 10        
        add al, [esi]       
        inc esi             
        loop process_age_digits 
     
    ; L'âge est maintenant stocké dans le registre EAX
    buffer_end_reached:
        mov ebx, [max_age]
        cmp eax, ebx
        jg update_age_vars
        ; Incrémenter nb_personnes pour indiquer qu'une personne de plus a été ajoutée
        call increment_personnes
        jmp _start
        
    update_age_vars:
        mov [max_age], eax                
        movzx ebx, byte [nb_personnes]    
        mov dword [max_age_index], ebx    
        call increment_personnes
        jmp _start
lister_personnes:
    ; Vérifier si le tableau est vide
    mov al, [nb_personnes]
    cmp al, 0
    je empty_table
    ; Message d'affichage
    mov eax, 4
    mov ebx, 1
    mov ecx, liste_personnes_msg
    mov edx, liste_personnes_msg_len
    int 0x80
 
   
    ; Étape 1: Charger l'adresse de base du tableau "personnes" dans ESI
    mov esi, personnes
    ; Charger le nombre de personnes dans ECX
    mov al, byte [nb_personnes] 
    xor ah, ah                  
    mov ecx, eax
    ; Convertir listing_index en caractère imprimable
    add byte [listing_index], '0' 
    ; Boucle d'affichage
    print_loop:
        inc byte [listing_index]
        push esi
        push ecx
        ; Afficher le numéro
        mov eax, 4
        mov ebx, 1
        mov ecx, listing_index   
        mov edx, 1  
        int 0x80 
        
        ; Afficher l'espace
        call print_space
 
        ; Afficher l'élément
        mov eax, 4
        mov ebx, 1
        mov ecx, esi
        mov edx, 32
        int 0x80 
        pop ecx
        pop esi
        add esi,32
        loop print_loop
     ; Réinitialiser la valeur de listing_index à 0
    mov byte [listing_index], 0
    jmp _start

afficher_personne_specifique:
    ; En cas de tableau vide
    mov al, [nb_personnes]
    cmp al, 0
    je empty_table
    ; Tableau non vide
    mov eax, 4
    mov ebx, 1
    mov ecx, search_msg
    mov edx, search_msg_len
    int 0x80
    ; Attendre l'entrée utilisateur pour choisir une option
    mov eax, 3
    mov ebx, 0
    mov ecx, search
    mov edx, 2 
    int 0x80
    ; Convertir le numéro
    mov eax, [search]
    and eax, 000000ffh
    sub eax, '0'
    ; Comparer la valeur à nb_personnes
    mov ebx, [nb_personnes]
    and ebx, 000000ffh
    cmp eax, ebx           
    jg invalid_search     
    cmp eax, 0
    jle invalid_search
    ; Afficher le numéro
    mov eax, 4
    mov ebx, 1
    mov ecx, search   
    mov edx, 1  
    int 0x80
 
    ; Afficher l'espace
    call print_space
    ; Obtenir l'adresse de la personne recherchée
    xor esi, esi
    mov al, [search]
    sub al, '0'
    mov esi, eax
    dec esi
    imul esi, 32
    add esi, personnes
    ; Afficher la personne
    mov eax, 4
    mov ebx, 1
    mov ecx, esi
    mov edx, 32
    int 0x80 
    jmp _start
    
 
invalid_search:
    ; Afficher un message d'erreur
    mov eax, 4                   
    mov ebx, 1                   
    mov ecx, not_found_msg           
    mov edx, not_found_msg_len       
    int 0x80                     
    jmp _start
 
empty_table:
    mov eax, 4
    mov ebx, 1
    mov ecx, empty_table_msg
    mov edx, empty_table_msg_len
    int 0x80
    jmp _start
 
print_space:
    mov eax, 4
    mov ebx, 1
    mov ecx, space
    mov edx, 1
    int 0x80
    ret
print_new_line:
    mov eax, 4           
    mov ebx, 1           
    mov ecx, newline     
    mov edx, 1           
    int 0x80
    ret
clear_input_buffer:
    mov edi, input_buffer
    mov ecx, 32
    clear_loop:
        mov byte [edi], 0   
        inc edi             
        loop clear_loop     
    ret
increment_personnes:
    inc byte [nb_personnes]
    ret
quit:
    mov eax, 1
    xor ebx, ebx
    int 0x80
display_menu:
    mov eax, 4
    mov ebx, 1
    mov ecx, menu_msg
    mov edx, menu_msg_len
    int 0x80
    ; Attendre l'entrée utilisateur pour choisir une option
    mov eax, 3
    mov ebx, 0
    mov ecx, user_choice
    mov edx, 2 
    int 0x80
    ; Convertir le choix en nombre
    mov eax, [user_choice]
    and eax, 000000ffh
    sub eax, '0'
manage_choice:
    cmp eax, 1
    je enregistrer_personnel
    
    cmp eax, 2
    je lister_personnes
    cmp eax, 3
    je afficher_personne_specifique
  
    cmp eax, 5
    je quit
    ; Sinon
    call invalid_in
    jmp _start
 
invalid_input:
    mov eax, 4                   
    mov ebx, 1                   
    mov ecx, invalid_in           
    mov edx, invalid_in_len       
    int 0x80
    ret
