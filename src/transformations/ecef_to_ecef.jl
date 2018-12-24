#== # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
#
#   Rotations from an Earth-Centered Inertial (ECI) reference frame to another
#   ECI reference frame.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# References
#
#   [1] Vallado, D. A (2013). Fundamentals of Astrodynamics and Applications.
#       Microcosm Press, Hawthorn, CA, USA.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ==#

export rECEFtoECEF

"""
    function rECEFtoECEF([T,] ECEFo, ECEFf, JD_UTC::Number, eop_data)

Compute the rotation from an Earth-Centered, Earth-Fixed (`ECEF`) reference
frame to another ECEF reference frame at the Julian Day [UTC] `JD_UTC`. The
rotation description that will be used is given by `T`, which can be `DCM` or
`Quaternion`. The origin ECEF frame is selected by the input `ECEFo` and the
destination ECEF frame is selected by the input `ECEFf`. The model used to
compute the rotation is specified by the selection of the origin and destination
frames. Currently, only IAU-76/FK5 is supported.

# Rotation description

The rotations that aligns the origin ECEF frame with the destination ECEF frame
can be described by Direction Cosine Matrices or Quaternions. This is selected
by the parameter `T`.

The possible values are:

* `DCM`: The rotation will be described by a Direction Cosine Matrix.
* `Quaternion`: The rotation will be described by a Quaternion.

If no value is specified, then it falls back to `DCM`.

# Conversion model

The model that will be used to compute the rotation is automatically inferred
given the selection of the origin and destination frames. Currently, only the
IAU-76/FK5 model is supported.

# ECEF Frame

The supported ECEF frames for both origin `ECEFo` and destination `ECEFf` are:

* `ITRF()`: ECEF will be selected as the International Terrestrial Reference
            Frame (ITRF).
* `PEF()`: ECEF will be selected as the Pseudo-Earth Fixed (PEF) reference
           frame.

# EOP Data

The conversion between the supported ECEF frames **always** depends on EOP Data
(see `get_iers_eop` and `read_iers_eop`). If IAU-76/FK5 model is used, then the
type of `eop_data` must be `EOPData_IAU1980`.

# Returns

The rotation description represented by `T` that rotates the ECEF reference
frame into alignment with the ECI reference frame.

# Examples

```julia-repl
julia> eop_IAU1980 = get_iers_eop(:IAU1980);

julia> rECEFtoECEF(PEF(), ITRF(), DatetoJD(1986,6,19,21,35,0), eop_IAU1980)
3×3 StaticArrays.SArray{Tuple{3,3},Float64,2,9}:
  1.0          0.0         4.35684e-7
  0.0          1.0         1.44762e-6
 -4.35684e-7  -1.44762e-6  1.0

julia> rECEFtoECEF(Quaternion, PEF(), ITRF(), DatetoJD(1986,6,19,21,35,0), eop_IAU1980)
Quaternion{Float64}:
  + 0.9999999999997147 - 7.236343481310813e-7.i + 2.1765518308012794e-7.j + 0.0.k
```
"""
@inline rECEFtoECEF(T_ECEFo::T_ECEFs,
                    T_ECEFf::T_ECEFs,
                    JD_UTC::Number,
                    eop_data::EOPData_IAU1980) =
    rECEFtoECEF(DCM, T_ECEFo, T_ECEFf, JD_UTC, eop_data)

################################################################################
#                                  IAU-76/FK5
################################################################################

#                                 ITRF <=> PEF
# ==============================================================================

function rECEFtoECEF(T::T_ROT,
                     ::Type{Val{:ITRF}},
                     ::Type{Val{:PEF}},
                     JD_UTC::Number,
                     eop_data::EOPData_IAU1980)
    # Get the EOP data related to the desired epoch.
    #
    # TODO: The difference is small, but should it be `JD_TT` or `JD_UTC`?
    x_p = eop_data.x(JD_UTC)*π/648000
    y_p = eop_data.y(JD_UTC)*π/648000

    # Return the rotation.
    rITRFtoPEF_fk5(T, x_p, y_p)
end

@inline rECEFtoECEF(T::T_ROT,
                    T_ECEFo::Type{Val{:PEF}},
                    T_ECEFf::Type{Val{:ITRF}},
                    JD_UTC::Number,
                    eop_data::EOPData_IAU1980) =
    inv_rotation(rECEFtoECEF(T, T_ECEFf, T_ECEFo, JD_UTC, eop_data))

