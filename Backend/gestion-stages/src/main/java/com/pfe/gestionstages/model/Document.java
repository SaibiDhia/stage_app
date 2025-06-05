package com.pfe.gestionstages.model;

import java.time.LocalDate;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Document {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String nomFichier;

    private String type; // Exemple : "Journal de Bord", "Bilan Version 1", etc.

    private LocalDate dateDepot;

    private String cheminFichier;

    @ManyToOne
    private User utilisateur; // Pour lier le document à l’étudiant
}
