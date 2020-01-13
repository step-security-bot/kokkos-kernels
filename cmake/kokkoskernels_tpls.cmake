FUNCTION(kokkoskernels_append_config_line LINE)
  GLOBAL_APPEND(KOKKOSKERNELS_TPL_EXPORTS "${LINE}")
ENDFUNCTION()

MACRO(KOKKOSKERNELS_ADD_TPL_OPTION NAME DEFAULT_VALUE DOCSTRING)
  KOKKOSKERNELS_ADD_OPTION(ENABLE_TPL_${NAME} ${DEFAULT_VALUE} BOOL ${DOCSTRING})
  KOKKOSKERNELS_ADD_OPTION(${NAME}_DIR "" PATH "Location of ${NAME} instal root")
  IF (DEFINED TPL_ENABLE_${NAME})
    IF (TPL_ENABLE_${NAME} AND NOT KOKKOSKERNELS_ENABLE_TPL_${NAME})
      MESSAGE(WARNING "Overriding KOKKOSKERNELS_ENABLE_TPL_${NAME}=OFF with TPL_ENABLE_${NAME}=ON")
      SET(KOKKOSKERNELS_ENABLE_TPL_${NAME} ON)
    ELSEIF(NOT TPL_ENABLE_${NAME} AND KOKKOSKERNELS_ENABLE_TPL_${NAME})
      MESSAGE(WARNING "Overriding KOKKOSKERNELS_ENABLE_TPL_${NAME}=ON with TPL_ENABLE_${NAME}=OFF")
      SET(KOKKOSKERNELS_ENABLE_TPL_${NAME} OFF)
    ENDIF()
  ENDIF()
  IF (KOKKOSKERNELS_ENABLE_TPL_${NAME})
    LIST(APPEND KOKKOSKERNELS_TPL_LIST ${NAME})
  ENDIF()
ENDMACRO()


MACRO(kokkoskernels_create_imported_tpl NAME)
  CMAKE_PARSE_ARGUMENTS(TPL
   "INTERFACE"
   "LIBRARY;IMPORTED_NAME"
   "LINK_LIBRARIES;INCLUDES;COMPILE_OPTIONS;LINK_OPTIONS"
   ${ARGN})

  IF (NOT TPL_IMPORTED_NAME)
    SET(TPL_IMPORTED_NAME KokkosKernels::${NAME})
  ENDIF()

  IF (KOKKOSKERNELS_HAS_TRILINOS)
    #TODO: we need to set a bunch of cache variables here
  ELSEIF (TPL_INTERFACE)
    ADD_LIBRARY(${NAME} INTERFACE)
    #Give this an importy-looking name
    ADD_LIBRARY(${TPL_IMPORTED_NAME} ALIAS ${NAME})
    IF (TPL_LIBRARY)
      MESSAGE(SEND_ERROR "TPL Interface library ${NAME} should not have an IMPORTED_LOCATION")
    ENDIF()
    #Things have to go in quoted in case we have multiple list entries
    IF(TPL_LINK_LIBRARIES)
      TARGET_LINK_LIBRARIES(${NAME} INTERFACE ${TPL_LINK_LIBRARIES})
      IF (NOT DEFINED ${NAME}_FOUND_INFO)
        SET(${NAME}_FOUND_INFO ${TPL_LINK_LIBRARIES})
      ENDIF()
    ENDIF()
    IF(TPL_INCLUDES)
      TARGET_INCLUDE_DIRECTORIES(${NAME} INTERFACE ${TPL_INCLUDES})
      IF (NOT DEFINED ${NAME}_FOUND_INFO)
        SET(${NAME}_FOUND_INFO ${TPL_INCLUDES})
      ENDIF()
    ENDIF()
    IF(TPL_COMPILE_OPTIONS)
      TARGET_COMPILE_OPTIONS(${NAME} INTERFACE ${TPL_COMPILE_OPTIONS})
    ENDIF()
    IF(TPL_LINK_OPTIONS)
      TARGET_LINK_LIBRARIES(${NAME} INTERFACE ${TPL_LINK_OPTIONS})
    ENDIF()
  ELSE()
    ADD_LIBRARY(${TPL_IMPORTED_NAME} UNKNOWN IMPORTED)
    IF(TPL_LIBRARY)
      SET_TARGET_PROPERTIES(${TPL_IMPORTED_NAME} PROPERTIES
        IMPORTED_LOCATION ${TPL_LIBRARY})
      IF (NOT DEFINED ${NAME}_FOUND_INFO)
        SET(${NAME}_FOUND_INFO ${TPL_LIBRARY})
      ENDIF()
    ENDIF()
    #Things have to go in quoted in case we have multiple list entries
    IF(TPL_LINK_LIBRARIES)
      SET_TARGET_PROPERTIES(${TPL_IMPORTED_NAME} PROPERTIES
        INTERFACE_LINK_LIBRARIES "${TPL_LINK_LIBRARIES}")
      IF (NOT DEFINED ${NAME}_FOUND_INFO)
        SET(${NAME}_FOUND_INFO ${TPL_LINK_LIBRARIES})
      ENDIF()
    ENDIF()
    IF(TPL_INCLUDES)
      SET_TARGET_PROPERTIES(${TPL_IMPORTED_NAME} PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${TPL_INCLUDES}")
      IF (NOT DEFINED ${NAME}_FOUND_INFO)
        SET(${NAME}_FOUND_INFO ${TPL_INCLUDES})
      ENDIF()
    ENDIF()
    IF(TPL_COMPILE_OPTIONS)
      SET_TARGET_PROPERTIES(${TPL_IMPORTED_NAME} PROPERTIES
        INTERFACE_COMPILE_OPTIONS "${TPL_COMPILE_OPTIONS}")
    ENDIF()
    IF(TPL_LINK_OPTIONS)
      SET_TARGET_PROPERTIES(${TPL_IMPORTED_NAME} PROPERTIES
        INTERFACE_LINK_LIBRARIES "${TPL_LINK_OPTIONS}")
    ENDIF()
  ENDIF()
ENDMACRO()

MACRO(kokkoskernels_find_header VAR_NAME HEADER TPL_NAME)
  CMAKE_PARSE_ARGUMENTS(TPL
   "ALLOW_SYSTEM_PATH_FALLBACK"
   ""
   "PATHS"
   ${ARGN})

  SET(${HEADER}_FOUND FALSE)
  SET(HAVE_CUSTOM_PATHS FALSE)
  IF(NOT ${HEADER}_FOUND AND DEFINED ${TPL_NAME}_ROOT)
    #ONLY look in the root directory
    FIND_PATH(${VAR_NAME} ${HEADER} PATHS ${${TPL_NAME}_ROOT}/include NO_DEFAULT_PATH)
    SET(HAVE_CUSTOM_PATHS TRUE)
  ENDIF()

  IF(NOT ${HEADER}_FOUND AND DEFINED KOKKOSKERNELS_${TPL_NAME}_DIR)
    #ONLY look in the root directory
    FIND_PATH(${VAR_NAME} ${HEADER} PATHS ${KOKKOSKERNELS_${TPL_NAME}_DIR}/include NO_DEFAULT_PATH)
    SET(HAVE_CUSTOM_PATHS TRUE)
  ENDIF()

  IF (NOT ${HEADER}_FOUND AND TPL_PATHS)
    #we got custom paths
    #ONLY look in these paths and nowhere else
    FIND_PATH(${VAR_NAME} ${HEADER} PATHS ${TPL_PATHS} NO_DEFAULT_PATH)
    SET(HAVE_CUSTOM_PATHS TRUE)
  ENDIF()

  IF (NOT HAVE_CUSTOM_PATHS OR TPL_ALLOW_SYSTEM_PATH_FALLBACK)
    #Now go ahead and look in system paths
    IF (NOT ${HEADER}_FOUND)
      FIND_PATH(${VAR_NAME} ${HEADER})
    ENDIF()
  ENDIF()
ENDMACRO()

MACRO(kokkoskernels_find_library VAR_NAME LIB TPL_NAME)
  CMAKE_PARSE_ARGUMENTS(TPL
   "ALLOW_SYSTEM_PATH_FALLBACK"
   ""
   "PATHS"
   ${ARGN})

  SET(${LIB}_FOUND FALSE)
  SET(HAVE_CUSTOM_PATHS FALSE)
  IF(NOT ${LIB}_FOUND AND DEFINED ${TPL_NAME}_ROOT)
    FIND_LIBRARY(${VAR_NAME} ${LIB} PATHS ${${TPL_NAME}_ROOT}/lib ${${TPL_NAME}_ROOT}/lib64 NO_DEFAULT_PATH)
    SET(HAVE_CUSTOM_PATHS TRUE)
  ENDIF()

  IF(NOT ${LIB}_FOUND AND DEFINED KOKKOSKERNELS_${TPL_NAME}_DIR)
    #we got root paths, only look in these paths and nowhere else
    FIND_LIBRARY(${VAR_NAME} ${LIB} 
      PATHS ${KOKKOSKERNELS_${TPL_NAME}_DIR}/lib ${KOKKOSKERNELS_${TPL_NAME}_DIR}/lib64 NO_DEFAULT_PATH)
    SET(HAVE_CUSTOM_PATHS TRUE)
  ENDIF()

  IF (NOT ${LIB}_FOUND AND TPL_PATHS)
    #we got custom paths, only look in these paths and nowhere else
    FIND_LIBRARY(${VAR_NAME} ${LIB} PATHS ${TPL_PATHS} NO_DEFAULT_PATH)
    SET(HAVE_CUSTOM_PATHS TRUE)
  ENDIF()


  IF (NOT HAVE_CUSTOM_PATHS OR TPL_ALLOW_SYSTEM_PATH_FALLBACK)
    IF (NOT ${LIB}_FOUND)
      #Now go ahead and look in system paths
      FIND_LIBRARY(${VAR_NAME} ${LIB})
    ENDIF()
  ENDIF()

ENDMACRO()

MACRO(kokkoskernels_find_imported NAME)
  CMAKE_PARSE_ARGUMENTS(TPL
   "INTERFACE;ALLOW_SYSTEM_PATH_FALLBACK"
   "HEADER;LIBRARY;IMPORTED_NAME"
   "HEADERS;LIBRARIES;HEADER_PATHS;LIBRARY_PATHS"
   ${ARGN})

  IF(NOT TPL_MODULE_NAME)
    SET(TPL_MODULE_NAME TPL${NAME})
  ENDIF()

  IF (TPL_ALLOW_SYSTEM_PATH_FALLBACK)
    SET(ALLOW_PATH_FALLBACK_OPT ALLOW_SYSTEM_PATH_FALLBACK)
  ELSE()
    SET(ALLOW_PATH_FALLBACK_OPT)
  ENDIF()

  IF (NOT TPL_IMPORTED_NAME)
    SET(TPL_IMPORTED_NAME KokkosKernels::${NAME})
  ENDIF()

  SET(${NAME}_INCLUDE_DIRS)
  IF (TPL_HEADER)
    KOKKOSKERNELS_FIND_HEADER(${NAME}_INCLUDE_DIRS ${TPL_HEADER} ${NAME} ${ALLOW_PATH_FALLBACK_OPT} PATHS ${TPL_HEADER_PATHS})
  ENDIF()

  FOREACH(HEADER ${TPL_HEADERS})
    KOKKOSKERNELS_FIND_HEADER(HEADER_FIND_TEMP ${HEADER} ${NAME} ${ALLOW_PATH_FALLBACK_OPT} PATHS ${TPL_HEADER_PATHS})
    IF(HEADER_FIND_TEMP)
      LIST(APPEND ${NAME}_INCLUDE_DIRS ${HEADER_FIND_TEMP})
    ENDIF()
  ENDFOREACH()

  SET(${NAME}_LIBRARY)
  IF(TPL_LIBRARY)
    KOKKOSKERNELS_FIND_LIBRARY(${NAME}_LIBRARY ${TPL_LIBRARY} ${NAME} ${ALLOW_PATH_FALLBACK_OPT} PATHS ${TPL_LIBRARY_PATHS})
  ENDIF()

  SET(${NAME}_FOUND_LIBRARIES)
  FOREACH(LIB ${TPL_LIBRARIES})
    #we want the actual name, not the name -lblas, etc
    SET(LIB_CLEAN ${LIB})
    STRING(FIND "${LIB}" "-l" PREFIX_IDX)
    IF (PREFIX_IDX STREQUAL "0")
      STRING(SUBSTRING ${LIB} 2 -1 LIB_CLEAN)
    ENDIF()

    KOKKOSKERNELS_FIND_LIBRARY(${LIB}_LOCATION ${LIB_CLEAN} ${NAME} ${ALLOW_PATH_FALLBACK_OPT} PATHS ${TPL_LIBRARY_PATHS})
    IF(${LIB}_LOCATION)
      LIST(APPEND ${NAME}_FOUND_LIBRARIES ${${LIB}_LOCATION})
    ELSE()
      SET(${NAME}_FOUND_LIBRARIES ${${LIB}_LOCATION})
      BREAK()
    ENDIF()
  ENDFOREACH()

  INCLUDE(FindPackageHandleStandardArgs)
  SET(TPL_VARS_NEEDED)
  IF (TPL_LIBRARY)
    LIST(APPEND TPL_VARS_NEEDED ${NAME}_LIBRARY)
  ENDIF()
  IF(TPL_HEADER)
    LIST(APPEND TPL_VARS_NEEDED ${NAME}_INCLUDE_DIRS)
  ENDIF()
  IF(TPL_LIBRARIES)
    LIST(APPEND TPL_VARS_NEEDED ${NAME}_FOUND_LIBRARIES)
  ENDIF()
  FIND_PACKAGE_HANDLE_STANDARD_ARGS(${TPL_MODULE_NAME} REQUIRED_VARS ${TPL_VARS_NEEDED})

  IF (${TPL_MODULE_NAME}_FOUND)
    SET(IMPORT_TYPE)
    IF (TPL_INTERFACE)
      SET(IMPORT_TYPE "INTERFACE")
    ENDIF()
    KOKKOSKERNELS_CREATE_IMPORTED_TPL(${NAME}
      ${IMPORT_TYPE}
      IMPORTED_NAME ${TPL_IMPORTED_NAME}
      INCLUDES "${${NAME}_INCLUDE_DIRS}"
      LIBRARY  "${${NAME}_LIBRARY}"
      LINK_LIBRARIES "${${NAME}_FOUND_LIBRARIES}")
  ENDIF()
ENDMACRO()

MACRO(kokkoskernels_export_imported_tpl NAME)
  CMAKE_PARSE_ARGUMENTS(TPL
   ""
   "IMPORTED_NAME"
   ""
   ${ARGN})
  IF (NOT TPL_IMPORTED_NAME)
    SET(TPL_IMPORTED_NAME KokkosKernels::${NAME})
  ENDIF()
  IF (NOT KOKKOSKERNELS_HAS_TRILINOS)
    GET_TARGET_PROPERTY(LIB_TYPE ${TPL_IMPORTED_NAME} TYPE)
    IF (${LIB_TYPE} STREQUAL "INTERFACE_LIBRARY")
      # This is not an imported target
      # This an interface library that we created
      INSTALL(
        TARGETS ${NAME}
        EXPORT KokkosKernelsTargets
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
      )
    ELSE()
      #make sure this also gets "exported" in the config file
      KOKKOSKERNELS_APPEND_CONFIG_LINE("IF(NOT TARGET ${NAME})")
      KOKKOSKERNELS_APPEND_CONFIG_LINE("ADD_LIBRARY(${NAME} UNKNOWN IMPORTED)")
      KOKKOSKERNELS_APPEND_CONFIG_LINE("SET_TARGET_PROPERTIES(${NAME} PROPERTIES")

      GET_TARGET_PROPERTY(TPL_LIBRARY ${TPL_IMPORTED_NAME} IMPORTED_LOCATION)
      IF(TPL_LIBRARY)
        KOKKOSKERNELS_APPEND_CONFIG_LINE("IMPORTED_LOCATION ${TPL_LIBRARY}")
      ENDIF()

      GET_TARGET_PROPERTY(TPL_INCLUDES ${TPL_IMPORTED_NAME} INTERFACE_INCLUDE_DIRECTORIES)
      IF(TPL_INCLUDES)
        KOKKOSKERNELS_APPEND_CONFIG_LINE("INTERFACE_INCLUDE_DIRECTORIES ${TPL_INCLUDES}")
      ENDIF()

      GET_TARGET_PROPERTY(TPL_COMPILE_OPTIONS ${TPL_IMPORTED_NAME} INTERFACE_COMPILE_OPTIONS)
      IF(TPL_COMPILE_OPTIONS)
        KOKKOSKERNELS_APPEND_CONFIG_LINE("INTERFACE_COMPILE_OPTIONS ${TPL_COMPILE_OPTIONS}")
      ENDIF()

      SET(TPL_LINK_OPTIONS)
      IF(${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.13.0")
        GET_TARGET_PROPERTY(TPL_LINK_OPTIONS ${TPL_IMPORTED_NAME} INTERFACE_LINK_OPTIONS)
      ENDIF()
      IF(TPL_LINK_OPTIONS)
        KOKKOSKERNELS_APPEND_CONFIG_LINE("INTERFACE_LINK_OPTIONS ${TPL_LINK_OPTIONS}")
      ENDIF()

      GET_TARGET_PROPERTY(TPL_LINK_LIBRARIES  ${TPL_IMPORTED_NAME} INTERFACE_LINK_LIBRARIES)
      IF(TPL_LINK_LIBRARIES)
        KOKKOSKERNELS_APPEND_CONFIG_LINE("INTERFACE_LINK_LIBRARIES ${TPL_LINK_LIBRARIES}")
      ENDIF()
      KOKKOSKERNELS_APPEND_CONFIG_LINE(")")
      KOKKOSKERNELS_APPEND_CONFIG_LINE("ENDIF()")
    ENDIF()
  ENDIF()
ENDMACRO()

MACRO(kokkoskernels_import_tpl NAME)
  CMAKE_PARSE_ARGUMENTS(TPL
   "NO_EXPORT;INTERFACE"
   ""
   ""
   ${ARGN})
  IF (TPL_INTERFACE)
    SET(TPL_IMPORTED_NAME ${NAME})
  ELSE()
    SET(TPL_IMPORTED_NAME KokkosKernels::${NAME})
  ENDIF()

  # Even though this policy gets set in the top-level CMakeLists.txt,
  # I have still been getting errors about ROOT variables being ignored
  # I'm not sure if this is a scope issue - but make sure
  # the policy is set before we do any find_package calls
  IF(${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.12.0")
    CMAKE_POLICY(SET CMP0074 NEW)
  ENDIF()

  IF (KOKKOSKERNELS_ENABLE_TPL_${NAME})
    #Tack on a TPL here to make sure we avoid using anyone else's find
    FIND_PACKAGE(TPL${NAME} REQUIRED MODULE)
    IF(NOT TARGET ${TPL_IMPORTED_NAME})
      MESSAGE(FATAL_ERROR "Find module succeeded for ${NAME}, but did not produce valid target ${TPL_IMPORTED_NAME}")
    ENDIF()
    IF(NOT TPL_NO_EXPORT)
      KOKKOSKERNELS_EXPORT_IMPORTED_TPL(${NAME} IMPORTED_NAME ${TPL_IMPORTED_NAME})
    ENDIF()
  ENDIF()
ENDMACRO(kokkoskernels_import_tpl)

FUNCTION(TARGET_LINK_FLAGS_PORTABLE LIBRARY)
  IF(${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.13")
    #great, this works the "right" way
    TARGET_LINK_OPTIONS(${LIBRARY} ${ARGN})
  ELSE()
    #bummer, this works the "hacky" way
    TARGET_LINK_LIBRARIES(${LIBRARY} ${ARGN})
  ENDIF()
ENDFUNCTION(TARGET_LINK_FLAGS_PORTABLE)

FUNCTION(kokkoskernels_link_tpl TARGET)
  CMAKE_PARSE_ARGUMENTS(TPL
   "PUBLIC;PRIVATE;INTERFACE"
   "IMPORTED_NAME"
   ""
   ${ARGN})
  #the name of the TPL
  SET(TPL ${TPL_UNPARSED_ARGUMENTS})
  IF (KOKKOSKERNELS_HAS_TRILINOS)
    #Do nothing, they will have already been linked
  ELSE()
    IF (NOT TPL_IMPORTED_NAME)
      SET(TPL_IMPORTED_NAME KokkosKernels::${TPL})
    ENDIF()
    IF (KOKKOSKERNELS_ENABLE_TPL_${TPL})
      IF (TPL_PUBLIC)
        TARGET_LINK_LIBRARIES(${TARGET} PUBLIC ${TPL_IMPORTED_NAME})
      ELSEIF (TPL_PRIVATE)
        TARGET_LINK_LIBRARIES(${TARGET} PRIVATE ${TPL_IMPORTED_NAME})
      ELSEIF (TPL_INTERFACE)
        TARGET_LINK_LIBRARIES(${TARGET} INTERFACE ${TPL_IMPORTED_NAME})
      ELSE()
        TARGET_LINK_LIBRARIES(${TARGET} ${TPL_IMPORTED_NAME})
      ENDIF()
    ENDIF()
  ENDIF()
ENDFUNCTION()

KOKKOSKERNELS_ADD_TPL_OPTION(BLAS OFF "Whether to enable BLAS")
#Default on if BLAS is enabled
KOKKOSKERNELS_ADD_TPL_OPTION(LAPACK ${KokkosKernels_ENABLE_TPL_BLAS} "Whether to enable LAPACK")
KOKKOSKERNELS_ADD_TPL_OPTION(MKL  OFF "Whether to enable MKL")
KOKKOSKERNELS_ADD_TPL_OPTION(MAGMA    OFF "Whether to enable MAGMA")

# Set F77_BLAS_MANGLE macro based on Fortran-C interface (unless already set
# by Trilinos or user)
IF (${F77_BLAS_MANGLE} STREQUAL "")
  IF (KOKKOSKERNELS_ENABLE_TPL_BLAS OR KOKKOSKERNELS_ENABLE_TPL_MKL OR KOKKOSKERNELS_ENABLE_TPL_MAGMA)
    ENABLE_LANGUAGE(C)
    ENABLE_LANGUAGE(Fortran)
    INCLUDE(FortranCInterface)
    IF (${FortranCInterface_GLOBAL_SUFFIX} STREQUAL "")
      SET(F77_BLAS_MANGLE "(name,NAME) ${FortranCInterface_GLOBAL_PREFIX}name")
    ELSE ()
      SET(F77_BLAS_MANGLE "(name,NAME) ${FortranCInterface_GLOBAL_PREFIX}name ## ${FortranCInterface_GLOBAL_SUFFIX}")
    ENDIF ()
  ENDIF()
ENDIF()

KOKKOSKERNELS_ADD_OPTION(NO_DEFAULT_CUDA_TPLS OFF BOOL "Whether CUDA TPLs should be enabled by default")
SET(CUBLAS_DEFAULT   ${KOKKOS_ENABLE_CUDA})
SET(CUSPARSE_DEFAULT ${KOKKOS_ENABLE_CUDA})
IF(KOKKOSKERNELS_NO_DEFAULT_CUDA_TPLS)
  SET(CUBLAS_DEFAULT   OFF)
  SET(CUSPARSE_DEFAULT OFF)
ENDIF()
KOKKOSKERNELS_ADD_TPL_OPTION(CUBLAS   ${CUBLAS_DEFAULT}     "Whether to enable CUBLAS")
KOKKOSKERNELS_ADD_TPL_OPTION(CUSPARSE ${CUSPARSE_DEFAULT}   "Whether to enable CUSPARSE")

IF (KOKKOSKERNELS_ENABLE_TPL_MAGMA)
  IF (KOKKOSKERNELS_HAS_TRILINOS)
    IF (F77_BLAS_MANGLE STREQUAL "(name,NAME) name ## _")
      SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DADD_ -fopenmp -lgfortran")
    ELSEIF (F77_BLAS_MANGLE STREQUAL "(name,NAME) NAME")
      SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DUPCASE -fopenmp -lgfortran")
    ELSEIF (F77_BLAS_MANGLE STREQUAL "(name,NAME) name")
      SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DNOCHANGE -fopenmp -lgfortran")
    ELSE ()
      MESSAGE(FATAL_ERROR "F77_BLAS_MANGLE ${F77_BLAS_MANGLE} detected while MAGMA only accepts Fortran mangling that is one of single underscore (-DADD_), uppercase (-DUPCASE), and no change (-DNOCHANGE)")
    ENDIF()
  ELSE()
    MESSAGE(FATAL_ERROR "KokkosKernels does not currently support MAGMA in standalone mode")
  ENDIF()
  LIST(APPEND TPL_LIST "MAGMA")
ENDIF()

# We need to do all the import work
IF (NOT KOKKOSKERNELS_HAS_TRILINOS)
  KOKKOSKERNELS_IMPORT_TPL(BLAS INTERFACE)
  KOKKOSKERNELS_IMPORT_TPL(LAPACK INTERFACE)
  KOKKOSKERNELS_IMPORT_TPL(MKL INTERFACE)
  KOKKOSKERNELS_IMPORT_TPL(CUBLAS INTERFACE)
  KOKKOSKERNELS_IMPORT_TPL(CUSPARSE)
ENDIF()

#Convert list to newlines (which CMake doesn't always like in cache variables)
STRING(REPLACE ";" "\n" KOKKOSKERNELS_TPL_EXPORT_TEMP "${KOKKOSKERNELS_TPL_EXPORTS}")
#Convert to a regular variable
UNSET(KOKKOSKERNELS_TPL_EXPORTS CACHE)
SET(KOKKOSKERNELS_TPL_EXPORTS ${KOKKOSKERNELS_TPL_EXPORT_TEMP})
