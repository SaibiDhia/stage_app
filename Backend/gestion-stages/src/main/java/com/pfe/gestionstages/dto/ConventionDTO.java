package com.pfe.gestionstages.dto;

import com.pfe.gestionstages.model.Convention;
import com.pfe.gestionstages.model.StatutConvention;
import lombok.Data;

import java.time.LocalDate;

@Data
public class ConventionDTO {
    private Long id;
    private String nomEtudiant;
    private String emailEtudiant;

    private String entreprise;
    private String adresse;
    private String representant;
    private String emailEntreprise;

    private String option;
    private String domaine;

    private LocalDate dateDebut;
    private LocalDate dateFin;

    private StatutConvention statut;

    public ConventionDTO(Convention c) {
        this.id = c.getId();
        this.nomEtudiant = c.getEtudiant().getFullName();
        this.emailEtudiant = c.getEtudiant().getEmail();
        this.entreprise = c.getEntreprise();
        this.adresse = c.getAdresse();
        this.representant = c.getRepresentant();
        this.emailEntreprise = c.getEmailEntreprise();
        this.option = c.getOption();
        this.domaine = c.getDomaine();
        this.dateDebut = c.getDateDebut();
        this.dateFin = c.getDateFin();
        this.statut = c.getStatut();
    }
}
