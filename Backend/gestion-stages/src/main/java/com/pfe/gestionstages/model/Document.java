package com.pfe.gestionstages.model;

import java.time.LocalDate;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.ManyToOne;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

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
    @Enumerated(EnumType.STRING)
    private Statut statut;

}
