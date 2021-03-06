#' AMMI Based Stability Parameter
#'
#' \code{ASTAB.AMMI} computes the AMMI Based Stability Parameter (ASTAB)
#' \insertCite{rao_use_2005}{ammistability} considering all significant
#' interaction principal components (IPCs) in the AMMI model. Using ASTAB, the
#' Simultaneous Selection Index for Yield and Stability (SSI) is also calculated
#' according to the argument \code{ssi.method}. \loadmathjax
#'
#' The AMMI Based Stability Parameter value (\mjseqn{ASTAB})
#' \insertCite{rao_use_2005}{ammistability} is computed as follows:
#'
#' \mjsdeqn{ASTAB = \sum_{n=1}^{N'}\lambda_{n}\gamma_{in}^{2}}
#'
#' Where, \mjseqn{N'} is the number of significant IPCs (number of IPC that were
#' retained in the AMMI model via F tests); \mjseqn{\lambda_{n}} is the singular
#' value for \mjseqn{n}th IPC and correspondingly \mjseqn{\lambda_{n}^{2}} is
#' its eigen value; and \mjseqn{\gamma_{in}} is the eigenvector value for
#' \mjseqn{i}th genotype.
#'
#' @inheritParams MASV.AMMI
#'
#' @return A data frame with the following columns:  \item{ASTAB}{The ASTAB
#'   values.} \item{SSI}{The computed values of simultaneous selection index for
#'   yield and stability.} \item{rASTAB}{The ranks of ASTAB values.}
#'   \item{rY}{The ranks of the mean yield of genotypes.} \item{means}{The mean
#'   yield of the genotypes.}
#'
#'   The names of the genotypes are indicated as the row names of the data
#'   frame.
#'
#' @importFrom methods is
#' @importFrom stats aggregate
#' @importFrom agricolae AMMI
#' @export
#'
#' @references
#'
#' \insertAllCited{}
#'
#' @seealso \code{\link[agricolae]{AMMI}}, \code{\link[ammistability]{SSI}}
#'
#' @examples
#' library(agricolae)
#' data(plrv)
#'
#' # AMMI model
#' model <- with(plrv, AMMI(Locality, Genotype, Rep, Yield, console = FALSE))
#'
#' # ANOVA
#' model$ANOVA
#'
#' # IPC F test
#' model$analysis
#'
#' # Mean yield and IPC scores
#' model$biplot
#'
#' # G*E matrix (deviations from mean)
#' array(model$genXenv, dim(model$genXenv), dimnames(model$genXenv))
#'
#' # With default n (N') and default ssi.method (farshadfar)
#' ASTAB.AMMI(model)
#'
#' # With n = 4 and default ssi.method (farshadfar)
#' ASTAB.AMMI(model, n = 4)
#'
#' # With default n (N') and ssi.method = "rao"
#' ASTAB.AMMI(model, ssi.method = "rao")
#'
#' # Changing the ratio of weights for Rao's SSI
#' ASTAB.AMMI(model, ssi.method = "rao", a = 0.43)
#'
ASTAB.AMMI <- function(model, n, alpha = 0.05,
                       ssi.method = c("farshadfar", "rao"), a = 1) {

  # Check model class
  if (!is(model, "AMMI")) {
    stop('"model" is not of class "AMMI"')
  }

  # Check alpha value
  if (!(0 < alpha && alpha < 1)) {
    stop('"alpha" should be between 0 and 1 (0 < alpha < 1)')
  }

  # Find number of significant IPCs according to F test
  if (missing(n) || is.null(n)) {
    n <- sum(model$analysis$Pr.F <= alpha, na.rm = TRUE)
  }

  # Check for n
  if (n %% 1 != 0 && length(n) != 1) {
    stop('"n" is not an integer vector of unit length')
  }

  # Check if n > N
  if (n > nrow(model$analysis)) {
    stop('"n" is greater than the number of IPCs in "model"')
  }

  ssi.method <- match.arg(ssi.method)

  # Fetch response (Yield)
  yresp <- setdiff(colnames(model$means), c("ENV", "GEN", "RESIDUAL"))

  # GxE matrix
  ge <- array(model$genXenv, dim(model$genXenv), dimnames(model$genXenv))
  # SVD
  svdge <- svd(ge)
  gamma.n <- svdge$u[, 1:n]
  lambda.n <- svdge$d[1:n]

  ASTAB <- rowSums(((gamma.n)^2) %*% diag(lambda.n))

  B <- model$means
  W <- aggregate(B[, yresp], by = list(model$means$GEN), FUN = mean, na.rm = TRUE)
  SSI_ASTAB <- SSI(y = W$x, sp = ASTAB, gen = W$Group.1,
                   method = ssi.method, a = a)
  ranking <- SSI_ASTAB
  colnames(ranking) <- c("ASTAB", "SSI", "rASTAB", "rY", "means")

  return(ranking)

}
