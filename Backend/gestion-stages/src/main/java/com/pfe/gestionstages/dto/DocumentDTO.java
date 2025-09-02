package com.pfe.gestionstages.dto;

import com.pfe.gestionstages.model.Document;

public class DocumentDTO {
    public Long id;
    public String email;
    public String type;
    public String statut;
    public String cheminFichier;
    public String dateDepot;
    public String optionParcours;

    public DocumentDTO(Document doc) {
        this.id = doc.getId();
        this.email = doc.getUtilisateur() != null ? doc.getUtilisateur().getEmail() : "";
        this.type = doc.getType();
        this.statut = doc.getStatut().name();
        this.cheminFichier = doc.getCheminFichier();
        this.dateDepot = doc.getDateDepot() != null ? doc.getDateDepot().toString() : "";
        this.optionParcours = (doc.getUtilisateur() != null && doc.getUtilisateur().getOptionParcours() != null)
                ? doc.getUtilisateur().getOptionParcours().name()
                : null;
    }
}

