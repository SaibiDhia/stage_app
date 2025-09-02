package com.pfe.gestionstages.dto;

import com.pfe.gestionstages.model.Role;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class RegisterRequest {
    private String fullName;
    private String email;
    private String password;
    private Role role;
    private String option;
}
