package com.pfe.gestionstages.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalDateTime;

import org.hibernate.annotations.CreationTimestamp;

@Entity
@Getter
@Setter
public class Convention {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    private User etudiant;

    private String entreprise;
    private String adresse;
    private String representant;
    private String emailEntreprise;

    private String option;
    private String domaine;

    private LocalDate dateDebut;
    private LocalDate dateFin;

    @Enumerated(EnumType.STRING)
    @Column(name = "statut")
    private StatutConvention statut;

    private String cheminConventionAdmin;
    private String cheminConventionSignee;

    @CreationTimestamp
@Column(updatable = false)
private LocalDateTime createdAt;

}
